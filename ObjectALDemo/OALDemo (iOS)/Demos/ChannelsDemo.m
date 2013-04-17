//
//  ChannelsDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "ChannelsDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import "ImageAndLabelButton.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"
#import "LampButton.h"
#import "CallFuncWithObject.h"

#define kSpaceBetweenButtons 50
#define kStartY 190


#pragma mark Private Methods

@interface ChannelsDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Play an effect on the 1 source channel. */
- (void) on1SourceChannel:(LampButton*) button;

/** Play an effect on the 2 source channel. */
- (void) on2SourceChannel:(LampButton*) button;

/** Play an effect on the 3 source channel. */
- (void) on3SourceChannel:(LampButton*) button;

/** Play an effect on the 8 source channel. */
- (void) on8SourceChannel:(LampButton*) button;

/** Turn off a source. */
- (void) onTurnOff:(LampButton*) button source:(ALChannelSource*) source;

@end

#pragma mark -
#pragma mark ChannelsDemo

@implementation ChannelsDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(255, 255, 255, 255)]))
	{
		[self buildUI];
	}
	return self;
}

- (void) dealloc
{
	[oneSourceChannel release];
	[twoSourceChannel release];
	[threeSourceChannel release];
	[eightSourceChannel release];
	[buffer release];

	[super dealloc];
}

- (void) buildUI
{
	[self buildAudioPanelWithTSeparator];
	[self addPanelTitle:@"Channels"];
	[self addPanelLine1:@"Tap a button repeatedly."];
	[self addPanelLine2:@"More sources allows more sounds at a time."];
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(screenSize.width/2, screenSize.height/2);

	LampButton* button;

	CGPoint pos = ccp(60, screenSize.height - kStartY);

	button = [LampButton buttonWithText:@"1 Source"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(on1SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	
	pos.y -= kSpaceBetweenButtons;

	button = [LampButton buttonWithText:@"2 Sources"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(on2SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];

	
	pos = ccp(center.x+40, screenSize.height - kStartY);

	button = [LampButton buttonWithText:@"3 Sources"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(on3SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"8 Sources"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(on8SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];

	
	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	// This is the only sound that gets played.  Notice that a single
	// buffer can be played by multiple sources simultaneously.
	buffer = [[[OpenALManager sharedInstance] bufferFromFile:@"Pew.caf"] retain];

	// Make some channels to play effects with.
	oneSourceChannel = [[ALChannelSource channelWithSources:1] retain];
	twoSourceChannel = [[ALChannelSource channelWithSources:2] retain];
	threeSourceChannel = [[ALChannelSource channelWithSources:3] retain];
	eightSourceChannel = [[ALChannelSource channelWithSources:8] retain];
}

- (void) turnOffAfterDelay:(LampButton*) button source:(ALChannelSource*) source
{
	[button stopAllActions];
	CCAction* action = [CCSequence actions:
						[CCDelayTime actionWithDuration:buffer.duration],
						[CallFuncWithObject actionWithTarget:self
													selector:@selector(onTurnOff:source:)
													  object:button
													  object:source],
						nil];
	
	[self runAction:action];
}

- (void) onTurnOff:(LampButton*) button source:(ALChannelSource*) source
{
	if(!source.playing)
	{
		button.isOn = NO;
	}
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) on1SourceChannel:(LampButton*) button
{
	[oneSourceChannel play:buffer];
	button.isOn = YES;
	[self turnOffAfterDelay:button source:oneSourceChannel];
}

- (void) on2SourceChannel:(LampButton*) button
{
	[twoSourceChannel play:buffer];
	button.isOn = YES;
	[self turnOffAfterDelay:button source:twoSourceChannel];
}

- (void) on3SourceChannel:(LampButton*) button
{
	[threeSourceChannel play:buffer];
	button.isOn = YES;
	[self turnOffAfterDelay:button source:threeSourceChannel];
}

- (void) on8SourceChannel:(LampButton*) button
{
	[eightSourceChannel play:buffer];
	button.isOn = YES;
	[self turnOffAfterDelay:button source:eightSourceChannel];
}

@end
