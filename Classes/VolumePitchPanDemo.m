//
//  VolumePitchPanDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "VolumePitchPanDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import "ObjectAL.h"


#pragma mark Private Methods

@interface VolumePitchPanDemo (Private)

- (void) buildUI;

@end


#pragma mark -
#pragma mark VolumePitchPanDemo

@implementation VolumePitchPanDemo

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
	[buffer release];
	[source release];

	[super dealloc];
}

- (void) buildUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CCSprite* track;
	CCLabel* label;
	Slider* slider;

	
	// Volume slider
	track = [CCSprite spriteWithFile:@"SliderTrackVertical.png"];
	track.scaleY = 100 / track.contentSize.height;
	slider = [VerticalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobVertical.png"]
									  target:self moveSelector:@selector(onVolumeChanged:) dropSelector:@selector(onVolumeChanged:)];
	slider.scale = 2.0f;
	slider.anchorPoint = ccp(0.5f, 0);
	slider.position = ccp(100, 100);
	[self addChild:slider];
	slider.value = 1.0f;
	label = [CCLabel labelWithString:@"Volume" fontName:@"Helvetica" fontSize:30];
	label.anchorPoint = ccp(0, 1);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x + slider.contentSize.width/2 * slider.scaleX + 10,
						 slider.position.y + slider.contentSize.height * slider.scaleY);
	[self addChild:label];
	
	
	// Pitch slider
	track = [CCSprite spriteWithFile:@"SliderTrackVertical.png"];
	track.scaleY = 100 / track.contentSize.height;
	slider = [VerticalSlider sliderWithTrack:track
										knob:[CCSprite spriteWithFile:@"SliderKnobVertical.png"]
									  target:self moveSelector:@selector(onPitchChanged:) dropSelector:@selector(onPitchChanged:)];
	slider.scale = 2.0f;
	slider.anchorPoint = ccp(0.5f, 0);
	slider.position = ccp(340, 100);
	[self addChild:slider];
	slider.value = 0.5f;
	label = [CCLabel labelWithString:@"Pitch" fontName:@"Helvetica" fontSize:30];
	label.anchorPoint = ccp(0, 1);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x + slider.contentSize.width/2 * slider.scaleX + 10,
						 slider.position.y + slider.contentSize.height * slider.scaleY);
	[self addChild:label];
	
	
	// Pan slider
	track = [CCSprite spriteWithFile:@"SliderTrackHorizontal.png"];
	track.scaleX = 220 / track.contentSize.width;
	slider = [HorizontalSlider sliderWithTrack:track
										  knob:[CCSprite spriteWithFile:@"SliderKnobHorizontal.png"]
										target:self moveSelector:@selector(onPanChanged:) dropSelector:@selector(onPanChanged:)];
	slider.scale = 2.0f;
	slider.anchorPoint = ccp(0.5f, 0);
	slider.position = ccp(center.x,10);
	[self addChild:slider];
	slider.value = 0.5f;
	label = [CCLabel labelWithString:@"Pan" fontName:@"Helvetica" fontSize:30];
	label.anchorPoint = ccp(0.5f, 0);
	label.color = ccBLACK;
	label.position = ccp(slider.position.x,
						 slider.position.y + slider.contentSize.height * slider.scaleY + 10);
	[self addChild:label];

	
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here so that it doesn't happen
	// prematurely.
	
	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	source = [[ALSource source] retain];
	buffer = [[[OALAudioSupport sharedInstance] bufferFromFile:@"ColdFunk.wav"] retain];
	
	[source play:buffer loop:YES];
}

- (void) onVolumeChanged:(Slider*) slider
{
	source.gain = slider.value;
}

- (void) onPitchChanged:(Slider*) slider
{
	source.pitch = slider.value * 2;
}

- (void) onPanChanged:(Slider*) slider
{
	source.pan = slider.value * 2 - 1;
}

@end
