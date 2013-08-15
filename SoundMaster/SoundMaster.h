//
//  SoundMaster.h
//  AS Roma
//
//  Created by Igor Khmurets on 12.08.13.
//  Copyright (c) 2013 Igor Khmurets. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MusicCompletionBlock)(void);

@interface SoundMaster : NSObject

/** Handy singleton */
+ (instancetype)sharedMaster;

@property (nonatomic) CGFloat musicVolume;
@property (nonatomic) CGFloat effectsVolume;
@property (nonatomic) NSTimeInterval musicFadeTime;
@property (readonly) BOOL isPlayingMusic;
@property (copy) MusicCompletionBlock musicCompletion;

#pragma mark - Effects (short sounds)

/** Plays sound effect with specified name. Relative volume is 
 setted by default or uses the value from -setRelativeVolume:effect: method. */
- (void)playEffect:(NSString *)fileName;
/** Plays sound effect with specified name and relative volume ingoring and 
 not resetting the value previously setted with -setRelativeVolume:effect: method. */
- (void)playEffect:(NSString *)fileName relativeVolume:(CGFloat)relativeVolume;

/** Use this method to preload sound effect to the buffer before
 calling -playEffect: for the first time. @discussion Significantly
 increases performance of the first effect's playback start @discussion */
- (void)preloadEffect:(NSString *)fileName;

/** Use this method to set constant relative volume level for specified sound effect. 
 It is usefull when your effect is considerably louder or quieter than average volume 
 level. -playEffect:relativeVolume: playes effect with specified relative volume
 but does no reset previously setted value. */
- (void)setRelativeVolume:(CGFloat)relativeVolume effect:(NSString *)fileName;

#pragma mark - Music

/** Plays music track with specified name from start. Without looping and fading in. */
- (void)playMusic:(NSString *)fileName;
/** Plays music track with specified name from start without
 fading in. Repeates from start infinitly if 'loop' is YES. */
- (void)playMusic:(NSString *)fileName loop:(BOOL)loop;
/** Plays music track with specified name from start. Repeates infinitly if
 'loop' is YES. Increases volume gradually from 0 to musicVolume property value if 'fadeIn' is YES. */
- (void)playMusic:(NSString *)fileName loop:(BOOL)loop fadeIn:(BOOL)fadeIn;

/** Use this method to preload music track to the buffer before
 calling -playMusic: for the first time. @discussion Significantly
 increases performance of the first music's playback start. @discussion */
- (void)preloadMusic:(NSString *)fileName;

/** Pauses music track */
- (void)pauseMusic;
/** Pauses music track. Decreases volume gradually from 'musicVolume' property value to 0 if 'fadeOut' is YES. */
- (void)pauseMusicWithFadeOut:(BOOL)fadeOut;

/** Playes music track from last position. Usually is used after -pauseMusic: was called */
- (void)resumeMusic;
/** Playes music from last position. Increases volume gradually from 0 to 'musicVolume'
 property value if 'fadeIn' is YES. Usually is used after -pauseMusic: was called */
- (void)resumeMusicWithFadeIn:(BOOL)fadeIn;

/** Performs gradual volume decrease of current music track and gradual volume increase
 of next music track. If 'loop' is YES the next music track will be playing looped */
- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop;
/** Same as -crossFadeToMusic:loop: method but with specified cross-fade duration */
- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop fadeDuration:(NSTimeInterval)duration;
/** Same as -crossFadeToMusic:loop:fadeDuration: method. But if 'waitUntilCurrentLoopEnds' is YES
 cross-fade process begins in the end of current music track loop */
- (void)crossFadeToMusic:(NSString *)fileName loop:(BOOL)loop fadeDuration:(NSTimeInterval)duration waitUntilCurrentLoopEnds:(BOOL)loopEnds;

/** Clears sound buffers. @discussion Use it when working with large audio files 
 or you don't need to work with previously used music and sounds. @discussion */
- (void)clearCache;

@end
