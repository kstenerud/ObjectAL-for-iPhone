//
//  HardwareDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-15.
//

#import "HardwareDemo.h"
#import "ImageButton.h"
#import <ObjectAL/ObjectAL.h>
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "CCLayer+AudioPanel.h"
#import "LampButton.h"
#import "VUMeter.h"


#define kSpaceBetweenButtons 40
#define kStartY 180

@interface HardwareDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Update method for the VU meters. */
- (void) vuStep;

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
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Hardware Monitoring"];
	[self addPanelLine1:@"Use your volume buttons and silent switch."];
	[self addPanelLine2:@"Not supported in the simulator."];
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CCLabelTTF* label;
	
	label = [CCLabelTTF labelWithString:@"Route:" fontName:@"Helvetica-Bold" fontSize:18];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(44, 34);
	[self addChild:label];
	
	routeLabel = [CCLabelTTF labelWithString:@"-" fontName:@"Helvetica" fontSize:18];
	routeLabel.anchorPoint = ccp(0, 0.5f);
	routeLabel.position = ccp(label.position.x + 60, label.position.y);
	[self addChild:routeLabel];

	label = [CCLabelTTF labelWithString:@"Volume:" fontName:@"Helvetica-Bold" fontSize:18];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(220, 34);
	[self addChild:label];
	
	volumeLabel = [CCLabelTTF labelWithString:@"0.0" fontName:@"Helvetica" fontSize:18];
	volumeLabel.anchorPoint = ccp(0, 0.5f);
	volumeLabel.position = ccp(label.position.x + 74, label.position.y);
	[self addChild:volumeLabel];
	
	muteLabel = [LampButton buttonWithText:@"Muted:"
									  font:@"Helvetica-Bold"
									  size:18
								lampOnLeft:NO
									target:nil
								  selector:nil];
	muteLabel.anchorPoint = ccp(0, 0.5f);
	muteLabel.position = ccp(350, 34);
	muteLabel.isTouchEnabled = NO;
	[self addChild:muteLabel];
	
	leftMeter = [[[VUMeter alloc] init] autorelease];
	leftMeter.anchorPoint = ccp(0, 0);
	leftMeter.position = ccp(100, 52);
	[self addChild:leftMeter];
	
	rightMeter = [[[VUMeter alloc] init] autorelease];
	rightMeter.anchorPoint = ccp(0, 0);
	rightMeter.position = ccp(250, 52);
	[self addChild:rightMeter];
	
	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	[[OALSimpleAudio sharedInstance] playBg:@"ColdFunk.caf" loop:YES];
	[OALSimpleAudio sharedInstance].backgroundTrack.meteringEnabled = YES;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	volume = [OALAudioSession sharedInstance].hardwareVolume;
	muted = [OALAudioSession sharedInstance].hardwareMuted;
	route = [[OALAudioSession sharedInstance].audioRoute retain];
	
	[volumeLabel setString:[NSString stringWithFormat:@"%.2f", volume]];
	muteLabel.isOn = [OALAudioSession sharedInstance].hardwareMuted;
	[routeLabel setString:[NSString stringWithFormat:@"%@", route]];
#endif

	[self schedule:@selector(step) interval:0.1f];
	[self schedule:@selector(vuStep)];
}

- (void) step
{
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
	float newVolume = [OALAudioSession sharedInstance].hardwareVolume;
	if(newVolume != volume)
	{
		volume = newVolume;
		[volumeLabel setString:[NSString stringWithFormat:@"%.2f", volume]];
	}

	muteLabel.isOn = [OALAudioSession sharedInstance].hardwareMuted;

	NSString* newRoute = [OALAudioSession sharedInstance].audioRoute;
	if(![newRoute isEqualToString:route])
	{
		[route autorelease];
		route = [newRoute retain];
		[routeLabel setString:[NSString stringWithFormat:@"%@", route]];
	}
#endif
}

- (void) vuStep
{
	OALAudioTrack* bg = [OALSimpleAudio sharedInstance].backgroundTrack;
	[bg updateMeters];
	leftMeter.db = [bg averagePowerForChannel:0];
	rightMeter.db = [bg averagePowerForChannel:1];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
