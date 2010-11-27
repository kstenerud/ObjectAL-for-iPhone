//
//  AudioSessionDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "AudioSessionDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "ObjectAL.h"
#import "CCLayer+AudioPanel.h"
#import "ImageButton.h"

#define kLeftX 50
#define kTopX 250
#define kHorizSpace 200
#define kVertSpace 40

#define UPPER_ROW_COL(A,B) ccp(kLeftX + (A)*kHorizSpace, kTopX - (B)*kVertSpace)
#define LOWER_ROW_COL(A,B) ccp(kLeftX + (A)*kHorizSpace, kTopX - 10 - (B)*kVertSpace)

#pragma mark Private Methods

@interface AudioSessionDemo (Private)

- (void) buildUI;

@end

#pragma mark -
#pragma mark AudioSessionDemo

@implementation AudioSessionDemo

- (id) init
{
	if(nil != (self = [super init]))
	{
		[self buildUI];
	}
	return self;
}

- (void) buildUI
{
	[self buildAudioPanel];
	[self addPanelTitle:@"Audio Session Settings"];
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	
	CCLabel* label;
	
	sessionActiveButton = [LampButton buttonWithText:@"Session Active"
												font:@"Helvetica"
												size:20
										  lampOnLeft:YES
											  target:self
											selector:@selector(onSessionActive:)];
	sessionActiveButton.anchorPoint = ccp(0, 0.5f);
	sessionActiveButton.position = UPPER_ROW_COL(0, 0);
	[self addChild:sessionActiveButton];
	
	suspendedButton = [LampButton buttonWithText:@"Suspended"
											font:@"Helvetica"
											size:20
									  lampOnLeft:YES
										  target:self
										selector:@selector(onSuspend:)];
	suspendedButton.anchorPoint = ccp(0, 0.5f);
	suspendedButton.position = UPPER_ROW_COL(1, 0);
	[self addChild:suspendedButton];
	
	
	allowIpodButton = [LampButton buttonWithText:@"Allow iPod"
											font:@"Helvetica"
											size:20
									  lampOnLeft:YES
										  target:self
										selector:@selector(onAllowIpod:)];
	allowIpodButton.anchorPoint = ccp(0, 0.5f);
	allowIpodButton.position = UPPER_ROW_COL(0, 1);
	[self addChild:allowIpodButton];
	
	ipodDuckingButton = [LampButton buttonWithText:@"iPod Ducking"
											  font:@"Helvetica"
											  size:20
										lampOnLeft:YES
											target:self
										  selector:@selector(onIpodDucking:)];
	ipodDuckingButton.anchorPoint = ccp(0, 0.5f);
	ipodDuckingButton.position = UPPER_ROW_COL(1, 1);
	[self addChild:ipodDuckingButton];
	
	honorSilentSwitchButton = [LampButton buttonWithText:@"Silent Switch"
													font:@"Helvetica"
													size:20
											  lampOnLeft:YES
												  target:self
												selector:@selector(onSilentSwitch:)];
	honorSilentSwitchButton.anchorPoint = ccp(0, 0.5f);
	honorSilentSwitchButton.position = UPPER_ROW_COL(0, 2);
	[self addChild:honorSilentSwitchButton];
	
	useHardwareButton = [LampButton buttonWithText:@"Use Hardware"
											  font:@"Helvetica"
											  size:20
										lampOnLeft:YES
											target:self
										  selector:@selector(onUseHardware:)];
	useHardwareButton.anchorPoint = ccp(0, 0.5f);
	useHardwareButton.position = UPPER_ROW_COL(1, 2);
	[self addChild:useHardwareButton];
	
	

	label = [CCLabel labelWithString:@"ALSource"
							fontName:@"Helvetica-Bold"
							fontSize:22];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = LOWER_ROW_COL(0, 3);
	label.position = ccp(label.position.x+4, label.position.y);
	[self addChild:label];
	
	playStopSource = [LampButton buttonWithText:@"Play/Stop"
										   font:@"Helvetica"
										   size:20
									 lampOnLeft:YES
										 target:self
									   selector:@selector(onPlayStopSource:)];
	playStopSource.anchorPoint = ccp(0, 0.5f);
	playStopSource.position = LOWER_ROW_COL(0, 4);
	[self addChild:playStopSource];
	
	pauseSource = [LampButton buttonWithText:@"Paused"
										font:@"Helvetica"
										size:20
								  lampOnLeft:YES
									  target:self
									selector:@selector(onPauseSource:)];
	pauseSource.anchorPoint = ccp(0, 0.5f);
	pauseSource.position = LOWER_ROW_COL(0, 5);
	[self addChild:pauseSource];
	
	
	label = [CCLabel labelWithString:@"AudioTrack"
							fontName:@"Helvetica-Bold"
							fontSize:22];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = LOWER_ROW_COL(1, 3);
	label.position = ccp(label.position.x+4, label.position.y);
	[self addChild:label];
	
	playStopTrack = [LampButton buttonWithText:@"Play/Stop"
										  font:@"Helvetica"
										  size:20
									lampOnLeft:YES
										target:self
									  selector:@selector(onPlayStopTrack:)];
	playStopTrack.anchorPoint = ccp(0, 0.5f);
	playStopTrack.position = LOWER_ROW_COL(1, 4);
	[self addChild:playStopTrack];
	
	pauseTrack = [LampButton buttonWithText:@"Paused"
									   font:@"Helvetica"
									   size:20
								 lampOnLeft:YES
									 target:self
								   selector:@selector(onPauseTrack:)];
	pauseTrack.anchorPoint = ccp(0, 0.5f);
	pauseTrack.position = LOWER_ROW_COL(1, 5);
	[self addChild:pauseTrack];
	
	
	
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}

- (void) dealloc
{
	[source release];
	[buffer release];
	[track release];
	
	[super dealloc];
}

- (void) refreshUI
{
	allowIpodButton.isOn = [OALAudioSupport sharedInstance].allowIpod;
	ipodDuckingButton.isOn = [OALAudioSupport sharedInstance].ipodDucking;
	honorSilentSwitchButton.isOn = [OALAudioSupport sharedInstance].honorSilentSwitch;
	useHardwareButton.isOn = [OALAudioSupport sharedInstance].useHardwareIfAvailable;
	sessionActiveButton.isOn = [OALAudioSupport sharedInstance].audioSessionActive;
	suspendedButton.isOn = [OALAudioSupport sharedInstance].suspended;

	playStopSource.isOn = source.playing;
	pauseSource.isOn = source.paused;

	playStopTrack.isOn = track.playing;
	pauseTrack.isOn = track.paused;
}

- (void) onEnterTransitionDidFinish
{
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	source = [[ALSource source] retain];
	buffer = [[[OALAudioSupport sharedInstance] bufferFromFile:@"ColdFunk.caf"] retain];
	track = [[OALAudioTrack track] retain];

	[self refreshUI];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onPlayStopSource:(LampButton*) button
{
	if(button.isOn)
	{
		[source play:buffer loop:YES];
	}
	else
	{
		[source stop];
		[self refreshUI];
	}
}

- (void) onPauseSource:(LampButton*) button
{
	source.paused = button.isOn;
}

- (void) onPlayStopTrack:(LampButton*) button
{
	if(button.isOn)
	{
		[track playFile:@"HappyAlley.caf" loops:-1];
	}
	else
	{
		[track stop];
		[self refreshUI];
	}
}

- (void) onPauseTrack:(LampButton*) button
{
	track.paused = button.isOn;
}


- (void) onAllowIpod:(LampButton*) button
{
	[OALAudioSupport sharedInstance].allowIpod = button.isOn;
}

- (void) onIpodDucking:(LampButton*) button
{
	[OALAudioSupport sharedInstance].ipodDucking = button.isOn;
}

- (void) onSilentSwitch:(LampButton*) button
{
	[OALAudioSupport sharedInstance].honorSilentSwitch = button.isOn;
}

- (void) onUseHardware:(LampButton*) button
{
	[OALAudioSupport sharedInstance].useHardwareIfAvailable = button.isOn;
}

- (void) onSessionActive:(LampButton*) button
{
	[OALAudioSupport sharedInstance].audioSessionActive = button.isOn;
	[self refreshUI];
}

- (void) onSuspend:(LampButton*) button
{
	[OALAudioSupport sharedInstance].suspended = button.isOn;
	[self refreshUI];
}

@end
