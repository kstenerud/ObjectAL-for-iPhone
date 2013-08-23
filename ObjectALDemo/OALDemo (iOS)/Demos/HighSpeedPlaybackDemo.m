//
//  HighSpeedPlaybackDemo.m
//  ObjectALDemo
//
//  Created by Karl Stenerud on 8/22/13.
//  Copyright (c) 2013 Karl Stenerud. All rights reserved.
//

#import "HighSpeedPlaybackDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"

#define kMinFireRate 1
#define kMaxFireRate 1000

@interface HighSpeedPlaybackDemo ()

@property(nonatomic, readwrite, assign) int fireRate1;
@property(nonatomic, readwrite, assign) int fireRate2;
@property(nonatomic, readwrite, retain) CCLabelTTF* fireRate1Label;
@property(nonatomic, readwrite, retain) CCLabelTTF* fireRate2Label;

@end

@implementation HighSpeedPlaybackDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super init]))
	{
		[self buildUI];
	}
	return self;
}

- (void) dealloc
{
    [_fireRate1Label release];
    [_fireRate2Label release];

    [super dealloc];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"High Speed Playback"];
	[self addPanelLine1:@"Plays back audio at the specified rate"];

	CGSize size = [[CCDirector sharedDirector] winSize];

	Slider* slider;

	CGPoint pos = ccp(160, 140);

	self.fireRate1Label = [CCLabelTTF labelWithString:@"X" fontName:@"Helvetica" fontSize:20];
	self.fireRate1Label.anchorPoint = ccp(1, 0);
	self.fireRate1Label.position = ccp(pos.x - 4, pos.y);
	[self addChild:self.fireRate1Label];

	slider = [self panelSliderWithTarget:self selector:@selector(onFireRate1Changed:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x +4, pos.y-6);
	slider.value = 0.0f;
	[self addChild:slider];

    pos.y -= 50;

	self.fireRate2Label = [CCLabelTTF labelWithString:@"X" fontName:@"Helvetica" fontSize:20];
	self.fireRate2Label.anchorPoint = ccp(1, 0);
	self.fireRate2Label.position = ccp(pos.x - 4, pos.y);
	[self addChild:self.fireRate2Label];

	slider = [self panelSliderWithTarget:self selector:@selector(onFireRate2Changed:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x +4, pos.y-6);
	slider.value = 0.0f;
	[self addChild:slider];
    
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    // We'll be saturating the effects channel, so set reservedSources to 28 to make sure it
    // doesn't choose a stereo source (default configuration is 28 mono and 4 stereo sources).
    [OALSimpleAudio sharedInstance].reservedSources = 28;
    self.fireRate1 = kMinFireRate;
    self.fireRate2 = kMinFireRate;
}

- (void) setFireRate1:(int) fireRate
{
    if(fireRate <= 0)
    {
        fireRate = 1;
    }

    _fireRate1 = fireRate;
    [self.fireRate1Label setString:[NSString stringWithFormat:@"1: %d / sec", fireRate]];
    [self unschedule:@selector(doFire1)];
    [self schedule:@selector(doFire1) interval:1.0f / fireRate];
}

- (void) setFireRate2:(int) fireRate
{
    if(fireRate <= 0)
    {
        fireRate = 1;
    }

    _fireRate2 = fireRate;
    [self.fireRate2Label setString:[NSString stringWithFormat:@"2: %d / sec", fireRate]];
    [self unschedule:@selector(doFire2)];
    [self schedule:@selector(doFire2) interval:1.0f / fireRate];
}

- (void) onFireRate1Changed:(Slider*) slider
{
    self.fireRate1 = slider.value * kMaxFireRate;
}

- (void) onFireRate2Changed:(Slider*) slider
{
    self.fireRate2 = slider.value * kMaxFireRate;
}

- (void) doFire1
{
    [[OALSimpleAudio sharedInstance] playEffect:@"Pew.caf"];
}

- (void) doFire2
{
    [[OALSimpleAudio sharedInstance] playEffect:@"Pow.caf"];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
