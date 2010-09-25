//
//  FadeDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-17.
//

#import "FadeDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "ImageButton.h"
#import "ImageAndLabelButton.h"
#import "ObjectAL.h"

#define kSpaceBetweenButtons 50

@interface FadeDemo (Private)

- (void) buildUI;

@end

@implementation FadeDemo

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(255, 255, 255, 255)]))
	{
		// Make sure audio is initialized.
		[SimpleIphoneAudio sharedInstance];

		[self buildUI];
	}
	return self;
}


- (void) buildUI
{
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);

	ImageButton* button;
	CCLabel* label;
	CGPoint position = ccp(20, size.height - 80);
	
	label = [CCLabel labelWithString:@"ObjectAL" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = position;
	[self addChild:label];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Play / Stop" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
												label:label
											   target:self
											 selector:@selector(onObjectALPlayStop:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade Out" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
												label:label
											   target:self
											 selector:@selector(onObjectALFadeOut:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade In" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
												label:label
											   target:self
											 selector:@selector(onObjectALFadeIn:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];

	position.y -= kSpaceBetweenButtons;

	label = [CCLabel labelWithString:@"Fading" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = position;
	[self addChild:label];
	oalFading = label;
	oalFading.visible = NO;
	

	position = ccp(center.x, size.height - 80);

	label = [CCLabel labelWithString:@"Background" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = position;
	[self addChild:label];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Play / Stop" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(onBackgroundPlayStop:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade Out" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(onBackgroundFadeOut:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade In" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(onBackgrounFadeIn:)];
	button.anchorPoint = ccp(0, 0.5);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fading" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5);
	label.color = ccBLACK;
	label.position = position;
	[self addChild:label];
	bgFading = label;
	bgFading.visible = NO;
	

	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}

- (void) onBackgroundPlayStop:(id) sender
{
	bgFading.visible = NO;
	if([SimpleIphoneAudio sharedInstance].bgPlaying)
	{
		[[SimpleIphoneAudio sharedInstance] stopBg];
	}
	else
	{
		[SimpleIphoneAudio sharedInstance].bgVolume = 1.0;
		[[SimpleIphoneAudio sharedInstance] playBg:@"ColdFunk.wav" loop:YES];
	}
}

- (void) dealloc
{
	// Note: Normally you wouldn't purge SimpleIphoneAudio when leaving a scene.
	// I'm doing it here to provide a clean slate for the other demos.
	[SimpleIphoneAudio purgeSharedInstance];
	
	[super dealloc];
}

- (void) onBackgroundFadeOut:(id) sender
{
	if([SimpleIphoneAudio sharedInstance].bgPlaying)
	{
		bgFading.visible = YES;
//		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:0.0];
		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:0.0 function:[OALLogarithmicFunction function]];
		[action runWithTarget:[SimpleIphoneAudio sharedInstance].backgroundTrack];
		//[[SimpleIphoneAudio sharedInstance].backgroundTrack fadeTo:0.0 duration:1.0 target:self selector:@selector(onBackgroundFadeComplete:)];
	}
}

- (void) onBackgrounFadeIn:(id) sender
{
	if([SimpleIphoneAudio sharedInstance].bgPlaying)
	{
		bgFading.visible = YES;
//		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:1.0];
		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:1.0 function:[OALLogarithmicFunction function]];
		[action runWithTarget:[SimpleIphoneAudio sharedInstance].backgroundTrack];
//		[[SimpleIphoneAudio sharedInstance].backgroundTrack fadeTo:1.0 duration:1.0 target:self selector:@selector(onBackgroundFadeComplete:)];
	}
}

- (void) onBackgroundFadeComplete:(id) sender
{
	bgFading.visible = NO;
}

- (void) onObjectALPlayStop:(id) sender
{
	oalFading.visible = NO;
	if(source.playing)
	{
		[source stop];
		source = nil;
	}
	else
	{
		source = [[SimpleIphoneAudio sharedInstance] playEffect:@"HappyAlley.wav" loop:YES];
	}
}

- (void) onObjectALFadeOut:(id) sender
{
	if(nil != source)
	{
		oalFading.visible = YES;
		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:0.0];
		[action runWithTarget:source];
//		[source fadeTo:0.0 duration:1.0 target:self selector:@selector(onObjectALFadeComplete:)];
	}
}

- (void) onObjectALFadeIn:(id) sender
{
	if(nil != source)
	{
		oalFading.visible = YES;
		OALAction* action = [OALGainAction actionWithDuration:1.0 endValue:1.0];
		[action runWithTarget:source];
//		[source fadeTo:1.0 duration:1.0 target:self selector:@selector(onObjectALFadeComplete:)];
	}
}

- (void) onObjectALFadeComplete:(id) sender
{
	oalFading.visible = NO;
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
