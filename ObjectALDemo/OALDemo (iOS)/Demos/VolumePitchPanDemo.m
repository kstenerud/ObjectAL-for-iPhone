//
//  VolumePitchPanDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "VolumePitchPanDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"


#pragma mark Private Methods

@interface VolumePitchPanDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Change the volume. */
- (void) onVolumeChanged:(Slider*) slider;

/** Change the pitch. */
- (void) onPitchChanged:(Slider*) slider;

/** Change the pan. */
- (void) onPanChanged:(Slider*) slider;

@end


#pragma mark -
#pragma mark VolumePitchPanDemo

@implementation VolumePitchPanDemo

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
	[buffer release];
	[source release];

	[super dealloc];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Volume, Pitch, Pan"];
	[self addPanelLine1:@"Use the sliders to alter playback."];
	[self addPanelLine2:@"Pan requires headphones."];
	
	CGSize size = [[CCDirector sharedDirector] winSize];

	CCLabelTTF* label;
	Slider* slider;

	CGPoint pos = ccp(160, 140);
	
	label = [CCLabelTTF labelWithString:@"Volume" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
	slider = [self panelSliderWithTarget:self selector:@selector(onVolumeChanged:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x +4, pos.y);
	slider.value = 1.0f;
	[self addChild:slider];

	pos.y -= 50;

	label = [CCLabelTTF labelWithString:@"Pitch" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
	slider = [self panelSliderWithTarget:self selector:@selector(onPitchChanged:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x + 4, pos.y);
	slider.value = 0.5f;
	[self addChild:slider];

	pos.y -= 50;
	
	label = [CCLabelTTF labelWithString:@"Pan" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
	slider = [self panelSliderWithTarget:self selector:@selector(onPanChanged:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x + 4, pos.y);
	slider.value = 0.5f;
	[self addChild:slider];

	
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
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	source = [[ALSource source] retain];
	
	// "Pan" uses OpenAL positioning, so we have to force ColdFunk.caf from stereo to mono.
	buffer = [[[OpenALManager sharedInstance] bufferFromFile:@"ColdFunk.caf" reduceToMono:YES] retain];
	
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
