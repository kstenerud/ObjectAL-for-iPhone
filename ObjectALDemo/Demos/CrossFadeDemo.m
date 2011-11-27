//
//  CrossFadeDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "CrossFadeDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import "ObjectAL.h"
#import "CCLayer+AudioPanel.h"

#pragma mark Private Methods

@interface CrossFadeDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Change the crossfade value. */
- (void) onCrossfadeChanged:(Slider*) slider;

@end


#pragma mark -
#pragma mark CrossFadeDemo

@implementation CrossFadeDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{
		[self buildUI];

		// We'll do an S-Curve fade.
		fadeFunction = [[OALSCurveFunction function] retain];
	}
	return self;
}

- (void) dealloc
{
	[fadeFunction release];
	[firstBuffer release];
	[firstSource release];
	[secondBuffer release];
	[secondSource release];

	[super dealloc];
}


- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Crossfading"];
	[self addPanelLine1:@"Use the slider to crossfade between tracks."];

	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CCLabelTTF* label;
	Slider* slider;

	label = [CCLabelTTF labelWithString:@"Cold Funk <------> Happy Alley"
							fontName:@"Helvetica"
							fontSize:22];
	label.anchorPoint = ccp(0.5f, 0);
	label.position = ccp(center.x, 110);
	[self addChild:label];
	
	slider = [self longPanelSliderWithTarget:self selector:@selector(onCrossfadeChanged:)];
	slider.anchorPoint = ccp(0.5f, 0);
	slider.position = ccp(label.position.x, label.position.y-30);
	slider.value = 0;
	[self addChild:slider];
	
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here instead of in init so that
	// it doesn't happen prematurely.
	
	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	// We're using OpenAL here, but the same concept works with AudioTracks.
	// For long duration files, AudioTracks will use SIGNIFICANTLY less ram.
	firstSource = [[ALSource source] retain];
	firstBuffer = [[[OpenALManager sharedInstance] bufferFromFile:@"ColdFunk.caf"] retain];
	
	secondSource = [[ALSource source] retain];
	secondBuffer = [[[OpenALManager sharedInstance] bufferFromFile:@"HappyAlley.caf"] retain];

	[firstSource play:firstBuffer loop:YES];
	[secondSource play:secondBuffer loop:YES];
	secondSource.gain = 0;
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onCrossfadeChanged:(Slider*) slider
{
	firstSource.gain = [fadeFunction valueForInput:1 - slider.value];
	secondSource.gain = [fadeFunction valueForInput:slider.value];
}


@end
