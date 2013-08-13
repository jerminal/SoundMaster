//
//  ViewController.m
//  SoundMasterExample
//
//  Created by Igor Khmurets on 12.08.13.
//  Copyright (c) 2013 gogosapiens. All rights reserved.
//

#import "ViewController.h"
#import "SoundMaster.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISlider *musicVolumeSlider;
@property (weak, nonatomic) IBOutlet UISlider *effectsVolumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *relativeVolumeLabel1;
@property (weak, nonatomic) IBOutlet UILabel *relativeVolumeLabel2;
@property (weak, nonatomic) IBOutlet UILabel *relativeVolumeLabel3;
@property (weak, nonatomic) IBOutlet UIStepper *relativeVolumeStepper1;
@property (weak, nonatomic) IBOutlet UIStepper *relativeVolumeStepper2;
@property (weak, nonatomic) IBOutlet UIStepper *relativeVolumeStepper3;
@property (weak, nonatomic) IBOutlet UISwitch *musicLoopsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *musicFadeInSwitch;
@property (weak, nonatomic) IBOutlet UIView *musicControlsView;
@property (weak, nonatomic) IBOutlet UIView *effectsControlsView;
@property (weak, nonatomic) IBOutlet UIButton *crossFadeBtn;
@property (weak, nonatomic) IBOutlet UISwitch *waitUntilLoopEndsSwitch;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, 658.f);
    [self.scrollView flashScrollIndicators];

    self.relativeVolumeLabel1.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper1.value * 100];
    self.relativeVolumeLabel2.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper2.value * 100];
    self.relativeVolumeLabel3.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper3.value * 100];

    [SoundMaster sharedMaster].musicVolume = self.musicVolumeSlider.value;
    [SoundMaster sharedMaster].effectsVolume = self.effectsVolumeSlider.value;
    [SoundMaster sharedMaster].musicFadeTime = 2.0;
    [[SoundMaster sharedMaster] preloadMusic:@"loop_1.caf"];
    [[SoundMaster sharedMaster] preloadMusic:@"loop_2.caf"];
    [[SoundMaster sharedMaster] preloadEffect:@"kick.caf"];
    [[SoundMaster sharedMaster] preloadEffect:@"shot.caf"];
    [[SoundMaster sharedMaster] preloadEffect:@"dub.caf"];
}

- (IBAction)musicVolumeSliderChanged:(id)sender
{
    [SoundMaster sharedMaster].musicVolume = self.musicVolumeSlider.value;
}

- (IBAction)effectsVolumeSliderChanged:(id)sender
{
    [SoundMaster sharedMaster].effectsVolume = self.effectsVolumeSlider.value;
}

- (IBAction)playMusicBtn:(id)sender
{
    [[SoundMaster sharedMaster] playMusic:@"loop_1.caf" loop:self.musicLoopsSwitch.on fadeIn:self.musicFadeInSwitch.on];
}

- (IBAction)pauseMusicBtn:(id)sender
{
    [[SoundMaster sharedMaster] pauseMusicWithFadeOut:self.musicFadeInSwitch.on];
}

- (IBAction)resumeMusicBtn:(id)sender
{
    [[SoundMaster sharedMaster] resumeMusicWithFadeIn:self.musicFadeInSwitch.on];
}

- (IBAction)playEffect1Btn:(id)sender
{
    [[SoundMaster sharedMaster] playEffect:@"kick.caf" relativeVolume:self.relativeVolumeStepper1.value];
}

- (IBAction)playEffect2Btn:(id)sender
{
    [[SoundMaster sharedMaster] playEffect:@"shot.caf" relativeVolume:self.relativeVolumeStepper2.value];
}

- (IBAction)playEffect3Btn:(id)sender
{
    [[SoundMaster sharedMaster] playEffect:@"dub.caf" relativeVolume:self.relativeVolumeStepper3.value];
}

- (IBAction)relativeVolumeStepper1Changed:(id)sender
{
    self.relativeVolumeLabel1.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper1.value * 100];
}

- (IBAction)relativeVolumeStepper2Changed:(id)sender
{
    self.relativeVolumeLabel2.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper2.value * 100];
}

- (IBAction)relativeVolumeStepper3Changed:(id)sender
{
    self.relativeVolumeLabel3.text = [NSString stringWithFormat:@"%.f%%", self.relativeVolumeStepper3.value * 100];
}

- (IBAction)crossFadeBtnPressed:(id)sender
{
    static BOOL b;
    if (b) {
        [[SoundMaster sharedMaster] crossFadeToMusic:@"loop_1.caf" loop:self.musicLoopsSwitch.on fadeDuration:1.5 waitUntilCurrentLoopEnds:self.waitUntilLoopEndsSwitch.on];
        if (self.waitUntilLoopEndsSwitch.on) {
            [self.crossFadeBtn setTitle:@"cross-fade to loop_2 (in the end of loop)" forState:UIControlStateNormal];
        } else {
            [self.crossFadeBtn setTitle:@"cross-fade to loop_2" forState:UIControlStateNormal];
        }
    } else {
        [[SoundMaster sharedMaster] crossFadeToMusic:@"loop_2.caf" loop:self.musicLoopsSwitch.on fadeDuration:1.5 waitUntilCurrentLoopEnds:self.waitUntilLoopEndsSwitch.on];
        if (self.waitUntilLoopEndsSwitch.on) {
            [self.crossFadeBtn setTitle:@"cross-fade to loop_1 (in the end of loop)" forState:UIControlStateNormal];
        } else {
            [self.crossFadeBtn setTitle:@"cross-fade to loop_1" forState:UIControlStateNormal];
        }
    }
    b = !b;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
