//
//  SoundMaster.m
//
//
//  Created by Igor Khmurets on 12.08.13.
//  Copyright (c) 2013 Igor Khmurets. All rights reserved.
//

#import "SoundMaster.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, ExtendedAVAudioPlayerType) {
    ExtendedAVAudioPlayerTypeEffect,
    ExtendedAVAudioPlayerTypeMusic
};

@interface ExtendedAVAudioPlayer : AVAudioPlayer

@property (nonatomic) CGFloat relativeVolume;
@property CGFloat currentRelativeVolume;
@property ExtendedAVAudioPlayerType type;

@end


@implementation ExtendedAVAudioPlayer

- (void)setVolume:(float)volume
{
    [super setVolume:MAX(0.f, volume * self.currentRelativeVolume)];
}

- (void)setRelativeVolume:(CGFloat)relativeVolume
{
    _relativeVolume = relativeVolume;
    self.currentRelativeVolume = relativeVolume;
}

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)outError
{
    self = [super initWithContentsOfURL:url error:outError];

    self.relativeVolume = 1.f;

    return self;
}

@end


#define DEFAULT_MUSIC_VOLUME 1.f
#define DEFAULT_EFFECTS_VOLUME 1.f

#define EFFECTS_REPEAT_DURATION 0.25

#define FADE_STEP 0.01
#define DEFAULT_MUSIC_FADE_TIME 1.0

@interface SoundMaster () <AVAudioPlayerDelegate>

@property (nonatomic) NSMutableDictionary *effects;
@property (nonatomic) NSMutableDictionary *effectsRelativeVolumes;
@property (nonatomic) NSMutableDictionary *musics;
@property NSString *currentMusicPath;
@property NSTimer *musicTimer;
@property NSTimer *musicTimer2;

@end

@implementation SoundMaster

- (instancetype)init
{
    self  = [super init];
    self.musicVolume = DEFAULT_MUSIC_VOLUME;
    self.effectsVolume = DEFAULT_EFFECTS_VOLUME;
    self.musicFadeTime = DEFAULT_MUSIC_FADE_TIME;
    return self;
}

+ (instancetype)sharedMaster
{
    static SoundMaster *master;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        master = [SoundMaster new];
    });
    return master;
}

#pragma mark - Public Methods

#pragma mark Effects

- (void)playEffect:(NSString *)fileName
{
    CGFloat relativeVolume;
    if (self.effectsRelativeVolumes[fileName]) {
        relativeVolume = [self.effectsRelativeVolumes[fileName] floatValue];
    } else {
        relativeVolume = 1.f;
    }
    [self playEffect:fileName relativeVolume:relativeVolume];
}

- (void)playEffect:(NSString *)fileName relativeVolume:(CGFloat)relativeVolume
{
    NSMutableSet *effectCopies = self.effects[fileName];
    ExtendedAVAudioPlayer *player;
    for (ExtendedAVAudioPlayer *tempPlayer in effectCopies) {
        if (!tempPlayer.isPlaying) {
            player = tempPlayer;
            break;
        }
    }
    if (!effectCopies) {
        effectCopies = [NSMutableSet new];
        self.effects[fileName] = effectCopies;
    }
    if (!player) {
        NSInteger effectsCountLimit = player.duration / EFFECTS_REPEAT_DURATION;
        if (effectCopies.count == effectsCountLimit) {
            return;
        }
        player = [self playerWithFileName:fileName];
        player.type = ExtendedAVAudioPlayerTypeEffect;
        [effectCopies addObject:player];
    }
    player.relativeVolume = relativeVolume;
    player.volume = self.effectsVolume;
    [player play];
}

- (void)preloadEffect:(NSString *)fileName
{
    NSMutableArray *effectCopies = self.effects[fileName];
    if (effectCopies.count > 0) {
        return;
    }
    ExtendedAVAudioPlayer *player = [self playerWithFileName:fileName];
    player.type = ExtendedAVAudioPlayerTypeEffect;
    if (!effectCopies) {
        effectCopies = [NSMutableArray new];
        self.effects[fileName] = effectCopies;
    }
    [effectCopies addObject:player];
    [player prepareToPlay];
}

- (void)setRelativeVolume:(CGFloat)relativeVolume effect:(NSString *)fileName
{
    self.effectsRelativeVolumes[fileName] = @(relativeVolume);
}

#pragma mark Music

- (void)preloadMusic:(NSString *)fileName
{
    ExtendedAVAudioPlayer *player = self.musics[fileName];
    if (!player) {
        player = [self playerWithFileName:fileName];
        player.type = ExtendedAVAudioPlayerTypeMusic;
        self.musics[fileName] = player;
        [player prepareToPlay];
    }
}

- (void)playMusic:(NSString *)fileName loop:(BOOL)loop fadeIn:(BOOL)fadeIn
{
    ExtendedAVAudioPlayer *currentPlayer = self.musics[self.currentMusicPath];
    [currentPlayer stop];
    currentPlayer.currentTime = 0.0;
    ExtendedAVAudioPlayer *player = self.musics[fileName];
    if (!player) {
        player = [self playerWithFileName:fileName];
        player.type = ExtendedAVAudioPlayerTypeMusic;
        self.musics[fileName] = player;
    }
    player.numberOfLoops = loop ? -1 : 0;
    player.currentRelativeVolume = 1.f;
    player.volume = self.musicVolume;
    if (fadeIn) {
        [self makeMusicPlayer:player fadeIn:YES duration:self.musicFadeTime timer:self.musicTimer];
    }
    [player play];
    self.currentMusicPath = fileName;
    _isPlayingMusic = YES;
}

- (void)playMusic:(NSString *)fileName loop:(BOOL)loop
{
    [self playMusic:fileName loop:loop fadeIn:NO];
}

- (void)playMusic:(NSString *)fileName
{
    [self playMusic:fileName loop:NO];
}

- (void)pauseMusicWithFadeOut:(BOOL)fadeOut
{
    ExtendedAVAudioPlayer *player = self.musics[self.currentMusicPath];
    if (player.isPlaying) {
        player.volume = self.musicVolume;
        if (fadeOut) {
            [self makeMusicPlayer:player fadeIn:NO duration:self.musicFadeTime timer:self.musicTimer];
        } else {
            [player pause];
        }
        _isPlayingMusic = NO;
    }
}

- (void)pauseMusic
{
    [self pauseMusicWithFadeOut:NO];
}

- (void)resumeMusicWithFadeIn:(BOOL)fadeIn
{
    ExtendedAVAudioPlayer *player = self.musics[self.currentMusicPath];
    [player play];
    player.volume = self.musicVolume;
    if (fadeIn) {
        [self makeMusicPlayer:player fadeIn:YES duration:self.musicFadeTime timer:self.musicTimer];
    }
    _isPlayingMusic = YES;
}

- (void)resumeMusic
{
    [self resumeMusicWithFadeIn:NO];
}

- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop fadeDuration:(NSTimeInterval)duration waitUntilCurrentLoopEnds:(BOOL)loopEnds
{
    ExtendedAVAudioPlayer *player = self.musics[self.currentMusicPath];
    if (player.isPlaying) {
        ExtendedAVAudioPlayer *nextPlayer = self.musics[fileName];
        if (!nextPlayer) {
            nextPlayer = [self playerWithFileName:fileName];
            nextPlayer.type = ExtendedAVAudioPlayerTypeMusic;
            self.musics[fileName] = nextPlayer;
        }
        nextPlayer.volume = self.musicVolume;
        nextPlayer.numberOfLoops = (loop ? -1 : 0);
        nextPlayer.currentTime = 0.0;
        if (duration > player.duration) {
            duration = player.duration;
        }
        if (duration > nextPlayer.duration) {
            duration = nextPlayer.duration;
        }
        if (loopEnds) {
            if (loop) {
                nextPlayer.currentTime = nextPlayer.duration - duration;
            }
            NSTimeInterval waitTime;
            if (player.duration - player.currentTime < duration) {
                waitTime = 2.0 * player.duration - player.currentTime - duration;
            } else {
                player.numberOfLoops = 0;
                waitTime = player.duration - player.currentTime - duration;
            }
            NSDictionary *info = @{@"duration" : @(duration), @"player" : player, @"nextPlayer" : nextPlayer, @"fileName" : fileName};
            [self performSelector:@selector(performCrossFade:) withObject:info afterDelay:waitTime];
        } else {
            [nextPlayer play];
            self.currentMusicPath = fileName;
            [self makeMusicPlayer:player fadeIn:NO duration:duration timer:self.musicTimer];
            [self makeMusicPlayer:nextPlayer fadeIn:YES duration:duration timer:self.musicTimer2];
        }
    } else {
        self.musicFadeTime = duration;
        [self playMusic:fileName loop:NO fadeIn:YES];
    }
}

- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop fadeDuration:(NSTimeInterval)duration
{
    [self crossFadeToMusic:fileName loop:loop fadeDuration:duration waitUntilCurrentLoopEnds:NO];
}

- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop
{
    [self crossFadeToMusic:fileName loop:loop fadeDuration:self.musicFadeTime];
}

- (void)clearCache
{
    ExtendedAVAudioPlayer *activePlayer;
    for (ExtendedAVAudioPlayer *player in self.musics.allValues) {
        if (player.isPlaying) {
            activePlayer = player;
            break;
        }
    }
    if (activePlayer && self.musics.count > 1) {
        NSMutableArray *mValues = self.musics.allValues.mutableCopy;
        NSInteger index = [mValues indexOfObject:activePlayer];
        [mValues exchangeObjectAtIndex:index withObjectAtIndex:0];
        [mValues removeObjectsInRange:NSMakeRange(1, mValues.count - 1)];
    } 
    [self.effects removeAllObjects];
    [self.effectsRelativeVolumes removeAllObjects];
}

#pragma mark - Public Properties

- (void)setMusicVolume:(CGFloat)musicVolume
{
    _musicVolume = musicVolume;
    ExtendedAVAudioPlayer *player = self.musics[self.currentMusicPath];
    if (player.isPlaying) {
        player.volume = musicVolume;
    }
}

- (void)setMusicFadeTime:(NSTimeInterval)musicFadeTime
{
    _musicFadeTime = MAX(0.1, musicFadeTime);
}

#pragma mark - Private Methods

- (void)performCrossFade:(NSDictionary *)info
{
    ExtendedAVAudioPlayer *player = info[@"player"];
    ExtendedAVAudioPlayer *nextPlayer = info[@"nextPlayer"];
    NSString *fileName = info[@"fileName"];
    NSTimeInterval duration = [info[@"duration"] doubleValue];
    [nextPlayer play];
    self.currentMusicPath = fileName;
    [self makeMusicPlayer:player fadeIn:NO duration:duration timer:self.musicTimer];
    [self makeMusicPlayer:nextPlayer fadeIn:YES duration:duration timer:self.musicTimer2];
}

- (ExtendedAVAudioPlayer *)playerWithFileName:(NSString *)fileName
{
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    ExtendedAVAudioPlayer *player = [[ExtendedAVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    player.delegate = self;
    return player;
}

- (void)makeMusicPlayer:(ExtendedAVAudioPlayer *)player fadeIn:(BOOL)fadeIn duration:(NSTimeInterval)duration timer:(NSTimer *)timer
{
    [timer invalidate];
    NSNumber *step = @(2.f / (duration / FADE_STEP));
    if (fadeIn) {
        player.relativeVolume = 1.f;
        player.currentRelativeVolume = 0.f;
    } else {
        player.relativeVolume = 0.f;
        player.currentRelativeVolume = 1.f;
    }
    self.musicTimer = [NSTimer scheduledTimerWithTimeInterval:FADE_STEP target:self selector:@selector(timerSelector:) userInfo:@{@"fadeIn" : @(fadeIn), @"player" : player, @"step" : step} repeats:YES];
    [self.musicTimer fire];
}

- (void)timerSelector:(NSTimer *)sender
{
    NSDictionary *userInfo = sender.userInfo;
    ExtendedAVAudioPlayer *player = userInfo[@"player"];
    NSTimeInterval step = [userInfo[@"step"] doubleValue];
    if ([userInfo[@"fadeIn"] boolValue]) {
        player.currentRelativeVolume += step;
        if (player.currentRelativeVolume >= player.relativeVolume) {
            player.currentRelativeVolume = player.relativeVolume;
            [sender invalidate];
        }
    } else {
        player.currentRelativeVolume -= step;
        if (player.currentRelativeVolume <= 0.f) {
            player.relativeVolume = 0.f;
            [player pause];
            [sender invalidate];
        }
    }
    player.volume = self.musicVolume;
}

- (void)audioPlayerDidFinishPlaying:(ExtendedAVAudioPlayer *)player successfully:(BOOL)flag
{
    if (player.type == ExtendedAVAudioPlayerTypeMusic) {
        _isPlayingMusic = NO;
        if (self.musicCompletion) {
            self.musicCompletion();
        }
    } else {
        [self releaseUnnecessaryEffectCopies:player];
    }
}

- (void)releaseUnnecessaryEffectCopies:(ExtendedAVAudioPlayer *)player
{
    NSString *fileName = player.url.lastPathComponent;
    NSMutableArray *effectCopies = self.effects[fileName];
    for (ExtendedAVAudioPlayer *tempPlayer in effectCopies) {
        if (tempPlayer.isPlaying) {
            return;
        }
    }
    if (effectCopies.count > 1) {
        [effectCopies removeObjectsInRange:NSMakeRange(1, effectCopies.count - 1)];
    }
}

#pragma mark - Private Properties

- (NSMutableDictionary *)effects
{
    if (!_effects) {
        _effects = [NSMutableDictionary new];
    }
    return _effects;
}

- (NSMutableDictionary *)musics
{
    if (!_musics) {
        _musics = [NSMutableDictionary new];
    }
    return _musics;
}

- (NSMutableDictionary *)effectsRelativeVolumes
{
    if (!_effectsRelativeVolumes) {
        _effectsRelativeVolumes = [NSMutableDictionary new];
    }
    return _effectsRelativeVolumes;
}

@end

