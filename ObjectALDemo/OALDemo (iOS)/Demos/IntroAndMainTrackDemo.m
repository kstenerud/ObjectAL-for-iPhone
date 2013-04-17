//
//  IntroAndMainTrackDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 12-09-06.
//

#import "IntroAndMainTrackDemo.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"
#import "ImageButton.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "LampButton.h"

#define kSpaceBetweenButtons 50
#define kStartY 166

#define kIntroTrackFileName @"ColdFunk-Intro.caf"
#define kLoopTrackFileName @"ColdFunk.caf"

@interface IntroAndMainTrackDemo ()

// Plays the main part of the track.
@property(nonatomic, readwrite, retain) OALAudioTrack* mainTrack;

// Intro method one: Use another audio track.
@property(nonatomic, readwrite, retain) OALAudioTrack* introTrack;

// Intro methods two and three: Use OpenAL.
@property(nonatomic, readwrite, retain) ALBuffer* mainBuffer;
@property(nonatomic, readwrite, retain) ALBuffer* introBuffer;
@property(nonatomic, readwrite, retain) ALSource* source;

@property(nonatomic, readwrite, assign) LampButton* audioTrackButton;
@property(nonatomic, readwrite, assign) LampButton* openALButton;
@property(nonatomic, readwrite, assign) LampButton* notificationButton;

@end


@implementation IntroAndMainTrackDemo

@synthesize introTrack = _introTrack;
@synthesize mainTrack = _mainTrack;
@synthesize introBuffer = _introBuffer;
@synthesize mainBuffer = _mainBuffer;
@synthesize source = _source;

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{
		[self buildUI];
	}
	return self;
}

- (void) dealloc
{
	[_introTrack release];
	[_mainTrack release];
	[_introBuffer release];
	[_mainBuffer release];
	[_source release];
	[super dealloc];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Intro and Main Track"];
	[self addPanelLine1:@"Plays intro, then switches to main track"];

	CGSize screenSize = [[CCDirector sharedDirector] winSize];

	LampButton* button;

	CGPoint pos = ccp(60, screenSize.height - kStartY);

	button = [LampButton buttonWithText:@"Audio Tracks (playAtTime)"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onAudioTracks)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
    self.audioTrackButton = button;

	pos.y -= kSpaceBetweenButtons;

	button = [LampButton buttonWithText:@"OpenAL + Audio Track (playAtTime)"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onOpenALHybrid)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
    self.openALButton = button;

	pos.y -= kSpaceBetweenButtons;

	button = [LampButton buttonWithText:@"OpenAL (notifications)"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onOpenALNotifications)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
    self.notificationButton = button;

	// Exit button
	ImageButton* exitButton = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	exitButton.anchorPoint = ccp(1,1);
	exitButton.position = ccp(screenSize.width, screenSize.height);
	[self addChild:exitButton z:250];
}

#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;

    self.source = [ALSource source];
    self.introBuffer = [[OpenALManager sharedInstance] bufferFromFile:kIntroTrackFileName];
    self.mainBuffer = [[OpenALManager sharedInstance] bufferFromFile:kLoopTrackFileName];

    self.introTrack = [OALAudioTrack track];
    [self.introTrack preloadFile:kIntroTrackFileName];

    self.mainTrack = [OALAudioTrack track];
    [self.mainTrack preloadFile:kLoopTrackFileName];
    // Main music track will loop on itself
    self.mainTrack.numberOfLoops = -1;
}

- (void) onExit
{
    [self stop];
    [super onExit];
}

- (void) stop
{
    [self.source unregisterAllNotifications];
    [self.source stop];
    [self.introTrack stop];
    [self.mainTrack stop];
    self.introTrack.currentTime = 0;
    self.mainTrack.currentTime = 0;
    [self turnOnLamp:nil];
}

- (void) turnOnLamp:(LampButton*) button
{
    self.audioTrackButton.isOn = button == self.audioTrackButton;
    self.openALButton.isOn = button == self.openALButton;
    self.notificationButton.isOn = button == self.notificationButton;
}

- (void) onAudioTracks
{
    // Uses two audio tracks: One for the intro and one for the main loop.
    // Playback on the main track is delayed by the duration of the intro.

    // This method has decent synchronization, even on slow devices.
    // It does, however, require you to play one of the tracks in a software
    // channel, which could cause CPU load if using complex compression formats
    // such as mp3 or aac. You could mitigate this by storing the intro track
    // as uncompressed PCM or lightly compressed such as IMA4.

    [self stop];
    [self turnOnLamp:self.audioTrackButton];

    // Play the main track at volume 0 to secure the hardware channel for it.
    self.mainTrack.volume = 0;
    [self.mainTrack play];

    // Start the intro playing on a software channel, then stop the main track.
    [self.introTrack play];
    [self.mainTrack stop];

    // Have the main track start again after the intro track's duration elapses.
    NSTimeInterval playAt = self.mainTrack.deviceCurrentTime + self.introTrack.duration;
    [self.mainTrack playAtTime:playAt];
    self.mainTrack.volume = 1;
}

- (void) onOpenALHybrid
{
    // Uses OpenAL for the intro and an audio track for the main loop.
    // Playback on the main track is delayed by the duration of the intro.

    // This sidesteps the software channel issue, but requires you to load
    // the entire decoded intro track (not the main track) into memory.
    // However, there are problems because of differences in how OpenAL and
    // AVAudioPlayer keep time (AVAudioPlayer is somewhat delayed).
    // You'll need to do some fudging of the playAt value to get it right.
    // I've left it as-is so you can hear the issue.

    [self stop];
    [self turnOnLamp:self.openALButton];

    [self.source play:self.introBuffer];

    // Have the main track start again after the intro buffer's duration elapses.
    NSTimeInterval playAt = self.mainTrack.deviceCurrentTime + self.introBuffer.duration;
    [self.mainTrack playAtTime:playAt];
    self.mainTrack.volume = 1;
}

- (void) onOpenALNotifications
{
    // Uses OpenAL for both the intro and the main loop.
    // Uses a callback to start the main loop playing.
    // Note: This only works on iOS 5+.

    // This is the most robust solution, giving absolutely perfect timing,
    // but it requires you to load the entire decoded contents of both the
    // intro track AND the main loop into memory. It also only works on iOS 5.0+

    [self stop];
    [self turnOnLamp:self.notificationButton];

    [self.mainTrack preloadFile:kLoopTrackFileName];

    __block typeof(self) blockSelf = self;
    [self.source registerNotification:AL_BUFFERS_PROCESSED
                             callback:^(__unused ALSource *source, __unused ALuint notificationID, __unused ALvoid *userData)
     {
         [blockSelf.source play:blockSelf.mainBuffer loop:YES];
         [blockSelf.source unregisterAllNotifications];
     }
                             userData:nil];
    [self.source play:self.introBuffer];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
