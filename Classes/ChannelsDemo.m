//
//  ChannelsDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "ChannelsDemo.h"
#import "Slider.h"
#import "ImageButton.h"
#import "IphoneAudioSupport.h"
#import "MainScene.h"
#import "BackgroundAudio.h"


#pragma mark Private Methods

@interface ChannelsDemo (Private)

- (void) buildUI;

@end

#pragma mark -
#pragma mark ChannelsDemo

@implementation ChannelsDemo

#pragma mark Object Management

+(id) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [self node]];
	return scene;
}

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(255, 255, 255, 255)]))
	{
		[self buildUI];

		// Initialize ObjectAL
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[ObjectAL sharedInstance].currentContext = context;
		
		[IphoneAudioSupport sharedInstance].handleInterruptions = YES;
		
		oneSourceChannel = [[ChannelSource channelWithSources:1] retain];
		twoSourceChannel = [[ChannelSource channelWithSources:2] retain];
		threeSourceChannel = [[ChannelSource channelWithSources:3] retain];
		eightSourceChannel = [[ChannelSource channelWithSources:8] retain];

		buffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"Pew.caf"] retain];
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

	// Note: Normally you wouldn't release the context and device when leaving a scene.
	// I'm doing it here to provide a clean slate for the other demos.
	[context release];
	[device release];

	// Ditto for BackgroundAudio
	[[BackgroundAudio sharedInstance] clear];

	[super dealloc];
}

- (void) buildUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CCSprite* track;
	CCLabel* label;
	Slider* slider;
	
	
	// BG Volume slider
	track = [CCSprite spriteWithFile:@"SliderTrackVertical.png"];
	track.scaleY = 75 / track.contentSize.height;
	slider = [VerticalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobVertical.png"]
									  target:self moveSelector:@selector(onBgVolume:) dropSelector:@selector(onBgVolume:)];
	slider.scale = 2.0;
	slider.anchorPoint = ccp(0, 1);
	slider.position = ccp(20,size.height - 4);
	[self addChild:slider];
	slider.value = 1.0;
	label = [CCLabel labelWithString:@"BG Volume" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 1);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x + slider.contentSize.width/2 * slider.scaleX + 20,
						 slider.position.y);
	[self addChild:label];
	
	
	// Effects Volume slider
	track = [CCSprite spriteWithFile:@"SliderTrackVertical.png"];
	track.scaleY = 75 / track.contentSize.height;
	slider = [VerticalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobVertical.png"]
									  target:self moveSelector:@selector(onEffectsVolume:) dropSelector:@selector(onEffectsVolume:)];
	slider.scale = 2.0;
	slider.anchorPoint = ccp(0, 1);
	slider.position = ccp(20,size.height - 166);
	[self addChild:slider];
	slider.value = 1.0;
	label = [CCLabel labelWithString:@"FX Volume" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 1);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x + slider.contentSize.width/2 * slider.scaleX + 20,
						 slider.position.y);
	[self addChild:label];
	
	
	// Channel Buttons
	ImageButton* button;
	CGPoint position = ccp(center.x, size.height - 80);
	
	button = [ImageButton buttonWithImageFile:@"Ganymede.png" target:self selector:@selector(on1SourceChannel:)];
	button.position = position;
	[self addChild:button];
	label = [CCLabel labelWithString:@"1 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = ccp(button.position.x + 20,
						 button.position.y);
	[self addChild:label];
	
	position.y -= 60;
	button = [ImageButton buttonWithImageFile:@"Ganymede.png" target:self selector:@selector(on2SourceChannel:)];
	button.position = position;
	[self addChild:button];
	label = [CCLabel labelWithString:@"2 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = ccp(button.position.x + 20,
						 button.position.y);
	[self addChild:label];
	
	position.y -= 60;
	button = [ImageButton buttonWithImageFile:@"Ganymede.png" target:self selector:@selector(on3SourceChannel:)];
	button.position = position;
	[self addChild:button];
	label = [CCLabel labelWithString:@"3 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = ccp(button.position.x + 20,
						 button.position.y);
	[self addChild:label];
	
	position.y -= 60;
	button = [ImageButton buttonWithImageFile:@"Ganymede.png" target:self selector:@selector(on8SourceChannel:)];
	button.position = position;
	[self addChild:button];
	label = [CCLabel labelWithString:@"8 Source Channel" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = ccp(button.position.x + 20,
						 button.position.y);
	[self addChild:label];


	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	// Set to loop forever.
	[BackgroundAudio sharedInstance].numberOfLoops = -1;
	[[BackgroundAudio sharedInstance] playFile:@"PlanetKiller.mp3"];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onBgVolume:(Slider*) slider
{
	[BackgroundAudio sharedInstance].gain = slider.value;
}

- (void) onEffectsVolume:(Slider*) slider
{
	context.listener.gain = slider.value;
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
