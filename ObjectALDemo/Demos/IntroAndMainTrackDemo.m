//
//  IntroAndMainTrackDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 12-09-06.
//

#import "IntroAndMainTrackDemo.h"
#import "ObjectAL.h"
#import "CCLayer+AudioPanel.h"
#import "ImageButton.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "LampButton.h"

#define kSpaceBetweenButtons 50
#define kStartY 166

@interface IntroAndMainTrackDemo ()

// Plays the main part of the track.
@property(nonatomic, readwrite, retain) OALAudioTrack* mainTrack;

// Intro method one: Use another audio track.
@property(nonatomic, readwrite, retain) OALAudioTrack* introTrack;

// Intro methods two and three: Use OpenAL.
@property(nonatomic, readwrite, retain) ALBuffer* introBuffer;
@property(nonatomic, readwrite, retain) ALSource* introSource;

@property(nonatomic, readwrite, assign) LampButton* audioTrackButton;
@property(nonatomic, readwrite, assign) LampButton* openALButton;
@property(nonatomic, readwrite, assign) LampButton* notificationButton;

@end


@implementation IntroAndMainTrackDemo

@synthesize introTrack = _introTrack;
@synthesize mainTrack = _mainTrack;
@synthesize introBuffer = _introBuffer;
@synthesize introSource = _introSource;

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
	[_introSource release];
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

	button = [LampButton buttonWithText:@"OpenAL (playAtTime)"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onOpenAL)];
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
	// Initialize the OpenAL device and context here instead of in init so that
	// it doesn't happen prematurely.

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;

    self.introSource = [ALSource source];
    self.introBuffer = [[OpenALManager sharedInstance] bufferFromFile:@"ColdFunk-Intro.caf"];
    self.introSource.buffer = self.introBuffer;

    self.introTrack = [OALAudioTrack track];
    [self.introTrack preloadFile:@"ColdFunk-Intro.caf"];

    self.mainTrack = [OALAudioTrack track];
    [self.mainTrack preloadFile:@"ColdFunk.caf"];
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
    [self.introSource unregisterAllNotifications];
    [self.introSource stop];
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
    // Uses two audio tracks: One for the intro and one for the main music.
    // Playback on the main track is delayed by the duration of the intro.

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

- (void) onOpenAL
{
    // Uses OpenAL for the intro and an audio track for the main music.
    // Playback on the main track is delayed by the duration of the intro.

    [self stop];
    [self turnOnLamp:self.openALButton];

    [self.introSource play];

    // Have the main track start again after the intro buffer's duration elapses.
    NSTimeInterval playAt = self.mainTrack.deviceCurrentTime + self.introBuffer.duration;
    [self.mainTrack playAtTime:playAt];
    self.mainTrack.volume = 1;
}

- (void) onOpenALNotifications
{
    // Uses OpenAL for the intro and an audio track for the main music.
    // Uses a callback to start the main track playing.
    // Note: This only works on iOS 5+.

    [self stop];
    [self turnOnLamp:self.notificationButton];

    __block typeof(self) blockSelf = self;
    [self.introSource registerNotification:AL_BUFFERS_PROCESSED
                             callback:^(ALSource *source, ALuint notificationID, ALvoid *userData)
     {
         [blockSelf.mainTrack play];
     }
                             userData:nil];
    [self.introSource play];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
