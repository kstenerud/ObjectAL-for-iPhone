//
//  HardwareDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-15.
//

#import "HardwareDemo.h"
#import "ImageButton.h"
#import "ObjectAL.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"

@interface HardwareDemo (Private)

- (void) buildUI;

@end


@implementation HardwareDemo

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
	[route release];
	[super dealloc];
}

- (void) buildUI
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	
	CCLabel* label = [CCLabel labelWithString:@"Hardware Monitoring" fontName:@"Helvetica" fontSize:28];
	label.position = ccp(screenSize.width/2, screenSize.height-30);
	label.color = ccBLACK;
	label.visible = YES;
	[self addChild:label];
	
	label = [CCLabel labelWithString:@"Play with the hardware volume and mute controls on your device." fontName:@"Helvetica" fontSize:16];
	label.position = ccp(screenSize.width/2, screenSize.height-80);
	label.color = ccBLACK;
	label.visible = YES;
	[self addChild:label];
	
	label = [CCLabel labelWithString:@"Note: This is unsupported in the simulator!" fontName:@"Helvetica" fontSize:16];
	label.position = ccp(screenSize.width/2, screenSize.height-120);
	label.color = ccBLACK;
	label.visible = YES;
	[self addChild:label];
	
	
	
	routeLabel = [CCLabel labelWithString:@"Route: ?" fontName:@"Helvetica" fontSize:24];
	routeLabel.position = ccp(screenSize.width/2, 70);
	routeLabel.color = ccBLACK;
	routeLabel.visible = YES;
	[self addChild:routeLabel];
	
	volumeLabel = [CCLabel labelWithString:@"Volume: ?" fontName:@"Helvetica" fontSize:24];
	volumeLabel.position = ccp(screenSize.width/2, 40);
	volumeLabel.color = ccBLACK;
	[self addChild:volumeLabel];
		
	muteLabel = [CCLabel labelWithString:@"Muted" fontName:@"Helvetica" fontSize:24];
	muteLabel.position = ccp(screenSize.width/2, 10);
	muteLabel.color = ccBLACK;
	muteLabel.visible = NO;
	[self addChild:muteLabel];
	
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}

- (void) onEnterTransitionDidFinish
{
	[[OALSimpleAudio sharedInstance] playBg:@"ColdFunk.wav" loop:YES];
	
	volume = [OALAudioSupport sharedInstance].hardwareVolume;
	muted = [OALAudioSupport sharedInstance].hardwareMuted;
	route = [[OALAudioSupport sharedInstance].audioRoute retain];
	
	[volumeLabel setString:[NSString stringWithFormat:@"Volume: %f", volume]];
	muteLabel.visible = [OALAudioSupport sharedInstance].hardwareMuted;
	[routeLabel setString:[NSString stringWithFormat:@"Route: %@", route]];

	[self schedule:@selector(step) interval:0.1];
}

- (void) step
{
	float newVolume = [OALAudioSupport sharedInstance].hardwareVolume;
	if(newVolume != volume)
	{
		volume = newVolume;
		[volumeLabel setString:[NSString stringWithFormat:@"Volume: %f", volume]];
	}

	muteLabel.visible = [OALAudioSupport sharedInstance].hardwareMuted;

	NSString* newRoute = [OALAudioSupport sharedInstance].audioRoute;
	if(![newRoute isEqualToString:route])
	{
		[route autorelease];
		route = [newRoute retain];
		[routeLabel setString:[NSString stringWithFormat:@"Route: %@", route]];
	}
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
