//
//  ChannelsDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "ChannelsDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import "ImageAndLabelButton.h"
#import "ObjectAL.h"


#pragma mark Private Methods

@interface ChannelsDemo (Private)

- (void) buildUI;

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
		
		backgroundTrack = [[OALAudioTrack track] retain];
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

	[backgroundTrack release];

	[super dealloc];
}

- (void) buildUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CCLabel* label;

	label = [CCLabel labelWithString:@"Tap a channel repeatedly" fontName:@"Helvetica" fontSize:20];
	label.position = ccp(size.width/2, size.height-30);
	label.color = ccBLACK;
	label.visible = YES;
	[self addChild:label];
	
	
	CCSprite* track;
	Slider* slider;
	
	
	// BG Volume slider
	track = [CCSprite spriteWithFile:@"SliderTrackHorizontal.png"];
	track.scaleX = 100 / track.contentSize.width;
	slider = [HorizontalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobHorizontal.png"]
									  target:self moveSelector:@selector(onBgVolume:) dropSelector:@selector(onBgVolume:)];
	slider.scale = 2.0f;
	slider.anchorPoint = ccp(0, 0);
	slider.position = ccp(20, 160);
	[self addChild:slider];
	slider.value = 1.0f;
	label = [CCLabel labelWithString:@"BG Volume" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x, slider.position.y + slider.contentSize.height*slider.scaleY + 4);
	[self addChild:label];
	
	
	// Effects Volume slider
	track = [CCSprite spriteWithFile:@"SliderTrackHorizontal.png"];
	track.scaleX = 100 / track.contentSize.width;
	slider = [HorizontalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobHorizontal.png"]
									  target:self moveSelector:@selector(onEffectsVolume:) dropSelector:@selector(onEffectsVolume:)];
	slider.scale = 2.0f;
	slider.anchorPoint = ccp(0, 0);
	slider.position = ccp(20, 44);
	[self addChild:slider];
	slider.value = 1.0f;
	label = [CCLabel labelWithString:@"FX Volume" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x, slider.position.y + slider.contentSize.height*slider.scaleY + 4);
	[self addChild:label];
	
	
	// Channel Buttons
	ImageAndLabelButton* button;
	CGPoint position = ccp(center.x, size.height - 80);
	
	label = [CCLabel labelWithString:@"1 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(on1SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= 60;

	label = [CCLabel labelWithString:@"2 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(on2SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= 60;
	
	label = [CCLabel labelWithString:@"3 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(on3SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= 60;
	
	label = [CCLabel labelWithString:@"8 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(on8SourceChannel:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];


	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here so that it doesn't happen
	// prematurely.
	
	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	// This is the only sound that gets played.  Notice that a single
	// buffer can be played by multiple sources simultaneously.
	buffer = [[[OALAudioSupport sharedInstance] bufferFromFile:@"Pew.caf"] retain];

	// Make some channels to play effects with.
	oneSourceChannel = [[ALChannelSource channelWithSources:1] retain];
	twoSourceChannel = [[ALChannelSource channelWithSources:2] retain];
	threeSourceChannel = [[ALChannelSource channelWithSources:3] retain];
	eightSourceChannel = [[ALChannelSource channelWithSources:8] retain];
	
	// Load and loop bg track forever.
	[backgroundTrack playFile:@"PlanetKiller.mp3" loops:-1];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onBgVolume:(Slider*) slider
{
	backgroundTrack.gain = slider.value;
}

- (void) onEffectsVolume:(Slider*) slider
{
	[OpenALManager sharedInstance].currentContext.listener.gain = slider.value;
}

- (void) on1SourceChannel:(Slider*) slider
{
	[oneSourceChannel play:buffer];
}

- (void) on2SourceChannel:(Slider*) slider
{
	[twoSourceChannel play:buffer];
}

- (void) on3SourceChannel:(Slider*) slider
{
	[threeSourceChannel play:buffer];
}

- (void) on8SourceChannel:(Slider*) slider
{
	[eightSourceChannel play:buffer];
}


@end
