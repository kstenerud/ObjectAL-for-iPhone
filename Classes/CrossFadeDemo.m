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

#pragma mark Private Methods

@interface CrossFadeDemo (Private)

- (void) buildUI;

@end


#pragma mark -
#pragma mark CrossFadeDemo

@implementation CrossFadeDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(255, 255, 255, 255)]))
	{
		[self buildUI];

		// Initialize ObjectAL
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[OpenALManager sharedInstance].currentContext = context;
		
		[IphoneAudioSupport sharedInstance].handleInterruptions = YES;
		
		firstSource = [[ALSource source] retain];
		firstBuffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"ColdFunk.wav"] retain];
		
		secondSource = [[ALSource source] retain];
		secondBuffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"HappyAlley.wav"] retain];

		// We'll do an S-Curve fade.
		fadeFunction = [[OALSCurveFunction function] retain];

		firstSource.gain = 1.0;
		secondSource.gain = 0.0;
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

	// Note: Normally you wouldn't release the context and device when leaving a scene.
	// I'm doing it here to provide a clean slate for the other demos.
	[context release];
	[device release];

	[super dealloc];
}


- (void) buildUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CCSprite* track;
	CCLabel* label;
	Slider* slider;
	

	// Crossfade slider
	track = [CCSprite spriteWithFile:@"SliderTrackHorizontal.png"];
	track.scaleX = 220 / track.contentSize.width;
	slider = [HorizontalSlider sliderWithTrack:track
										  knob:[CCSprite spriteWithFile:@"SliderKnobHorizontal.png"]
										target:self moveSelector:@selector(onCrossfadeChanged:) dropSelector:@selector(onCrossfadeChanged:)];
	slider.scale = 2.0;
	slider.anchorPoint = ccp(0.5, 0.5);
	slider.position = ccp(center.x,center.y);
	[self addChild:slider];
	slider.value = 0;
	label = [CCLabel labelWithString:@"Crossfade" fontName:@"Helvetica" fontSize:30];
	label.anchorPoint = ccp(0.5, 0);
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

- (void) onEnterTransitionDidFinish
{
	[firstSource play:firstBuffer loop:YES];
	[secondSource play:secondBuffer loop:YES];
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
