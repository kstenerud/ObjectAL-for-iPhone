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
	
	label = [CCLabel labelWithString:@"ALSource" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
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
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade Out" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
												label:label
											   target:self
											 selector:@selector(onObjectALFadeOut:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade In" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
												label:label
											   target:self
											 selector:@selector(onObjectALFadeIn:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];

	position.y -= kSpaceBetweenButtons;

	label = [CCLabel labelWithString:@"Fading" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
	label.color = ccBLACK;
	label.position = position;
	[self addChild:label];
	oalFading = label;
	oalFading.visible = NO;
	

	position = ccp(center.x, size.height - 80);

	label = [CCLabel labelWithString:@"AudioTrack" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
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
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade Out" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(onBackgroundFadeOut:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fade In" fontName:@"Helvetica" fontSize:24];
	label.color = ccBLACK;
	button = [ImageAndLabelButton buttonWithImageFile:@"Ganymede.png"
												label:label
											   target:self
											 selector:@selector(onBackgrounFadeIn:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = position;
	[self addChild:button];
	
	position.y -= kSpaceBetweenButtons;
	
	label = [CCLabel labelWithString:@"Fading" fontName:@"Helvetica" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
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

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here so that it doesn't happen
	// prematurely.
	[OALSimpleAudio sharedInstance];
}

- (void) onBackgroundPlayStop:(id) sender
{
	bgFading.visible = NO;
	if([OALSimpleAudio sharedInstance].bgPlaying)
	{
		[[OALSimpleAudio sharedInstance] stopBg];
	}
	else
	{
		[OALSimpleAudio sharedInstance].bgVolume = 1.0f;
		[[OALSimpleAudio sharedInstance] playBg:@"ColdFunk.wav" loop:YES];
	}
}

- (void) onBackgroundFadeOut:(id) sender
{
	if([OALSimpleAudio sharedInstance].bgPlaying)
	{
		bgFading.visible = YES;
		[[OALSimpleAudio sharedInstance].backgroundTrack fadeTo:0.0f duration:1.0f target:self selector:@selector(onBackgroundFadeComplete:)];

		// Alternatively, you could do this:
		//   OALAction* action = [OALSequentialActions actions:
		//						[OALGainAction actionWithDuration:1.0 endValue:0.0],
		//						[OALCall actionWithCallTarget:self selector:@selector(onBackgroundFadeComplete:)],
		//						nil];
		//   [action runWithTarget:[OALSimpleAudio sharedInstance].backgroundTrack];
		//
		// You could also specify a function like this:
		//   [OALGainAction actionWithDuration:1.0 endValue:0.0 function:[OALLogarithmicFunction function]];
	}
}

- (void) onBackgrounFadeIn:(id) sender
{
	if([OALSimpleAudio sharedInstance].bgPlaying)
	{
		bgFading.visible = YES;
		[[OALSimpleAudio sharedInstance].backgroundTrack fadeTo:1.0f duration:1.0f target:self selector:@selector(onBackgroundFadeComplete:)];

		// Alternatively, you could do this:
		//   OALAction* action = [OALSequentialActions actions:
		//						[OALGainAction actionWithDuration:1.0 endValue:1.0],
		//						[OALCall actionWithCallTarget:self selector:@selector(onBackgroundFadeComplete:)],
		//						nil];
		//   [action runWithTarget:[OALSimpleAudio sharedInstance].backgroundTrack];
		//
		// You could also specify a function like this:
		//   [OALGainAction actionWithDuration:1.0 endValue:1.0 function:[OALLogarithmicFunction function]];
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
		source = [[OALSimpleAudio sharedInstance] playEffect:@"HappyAlley.wav" loop:YES];
	}
}

- (void) onObjectALFadeOut:(id) sender
{
	if(nil != source)
	{
		oalFading.visible = YES;
		[source fadeTo:0.0f duration:1.0f target:self selector:@selector(onObjectALFadeComplete:)];

		// Alternatively, you could do this:
		//   OALAction* action = [OALSequentialActions actions:
		//						[OALGainAction actionWithDuration:1.0 endValue:0.0],
		//						[OALCall actionWithCallTarget:self selector:@selector(onObjectALFadeComplete:)],
		//						nil];
		//   [action runWithTarget:source];
		//
		// You could also specify a function like this:
		//   [OALGainAction actionWithDuration:1.0 endValue:0.0 function:[OALLogarithmicFunction function]];
	}
}

- (void) onObjectALFadeIn:(id) sender
{
	if(nil != source)
	{
		oalFading.visible = YES;
		[source fadeTo:1.0f duration:1.0f target:self selector:@selector(onObjectALFadeComplete:)];
		
		// Alternatively, you could do this:
		//   OALAction* action = [OALSequentialActions actions:
		//						[OALGainAction actionWithDuration:1.0 endValue:1.0],
		//						[OALCall actionWithCallTarget:self selector:@selector(onObjectALFadeComplete:)],
		//						nil];
		//   [action runWithTarget:source];
		//
		// You could also specify a function like this:
		//   [OALGainAction actionWithDuration:1.0 endValue:1.0 function:[OALLogarithmicFunction function]];
	}
}

- (void) onObjectALFadeComplete:(id) sender
{
	oalFading.visible = NO;
}

- (void) onExitPressed
{
	// These are needed when using cocos2d actions since the its action engine is less forgiving.
	[[OALSimpleAudio sharedInstance].backgroundTrack stopActions];
	[source stopActions];
	
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
