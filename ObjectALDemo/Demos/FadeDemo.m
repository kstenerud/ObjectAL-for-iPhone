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
#import "CCLayer+AudioPanel.h"

#define kSpaceBetweenButtons 40
#define kStartY 160

@interface FadeDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Start/stop the background track. */
- (void) onBackgroundPlayStop:(LampButton*) button;

/** Fade out the background track. */
- (void) onBackgroundFadeOut:(LampButton*) button;

/** Fade in the background track. */
- (void) onBackgroundFadeIn:(LampButton*) button;

/** Called when the fade completes. */
- (void) onBackgroundFadeComplete:(id) sender;

/** Start/stop the OpenAL source. */
- (void) onObjectALPlayStop:(LampButton*) button;

/** Fade the source out. */
- (void) onObjectALFadeOut:(LampButton*) button;

/** Fade the source in. */
- (void) onObjectALFadeIn:(LampButton*) button;

/** Called when the fade completes. */
- (void) onObjectALFadeComplete:(id) sender;

/** Exit the demo. */
- (void) onExitPressed;

@end

@implementation FadeDemo

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{
		[self buildUI];
	}
	return self;
}

- (void) buildUI
{
	[self buildAudioPanelWithTSeparator];
	[self addPanelTitle:@"Fading"];
	[self addPanelLine1:@"Click Start, then use fade buttons"];
	[self addPanelLine2:@"to start or cancel a fade."];
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(screenSize.width/2, screenSize.height/2);

	LampButton* button;
	CCLabelTTF* label;
	
	CGPoint pos = ccp(60, screenSize.height - kStartY);
	
	label = [CCLabelTTF labelWithString:@"ALSource" fontName:@"Helvetica-Bold" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(pos.x+10, pos.y);
	[self addChild:label];
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Start/Stop"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onObjectALPlayStop:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	startStopSourceButton = button;
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Fade Out"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onObjectALFadeOut:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	fadeOutSourceButton = button;
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Fade In"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onObjectALFadeIn:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	fadeInSourceButton = button;


	pos = ccp(center.x+40, screenSize.height - kStartY);

	label = [CCLabelTTF labelWithString:@"AudioTrack" fontName:@"Helvetica-Bold" fontSize:24];
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(pos.x+10, pos.y);
	[self addChild:label];
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Start/Stop"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onBackgroundPlayStop:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	startStopTrackButton = button;
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Fade Out"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onBackgroundFadeOut:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	fadeOutTrackButton = button;
	
	pos.y -= kSpaceBetweenButtons;
	
	button = [LampButton buttonWithText:@"Fade In"
								   font:@"Helvetica"
								   size:20
							 lampOnLeft:YES
								 target:self
							   selector:@selector(onBackgroundFadeIn:)];
	button.anchorPoint = ccp(0, 0.5f);
	button.position = pos;
	[self addChild:button];
	fadeInTrackButton = button;
	

	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here instead of in init so that
	// it doesn't happen prematurely.
	[OALSimpleAudio sharedInstance];
}

- (void) onBackgroundPlayStop:(LampButton*) button
{
	[[OALSimpleAudio sharedInstance].backgroundTrack stopFade];
	fadeInTrackButton.isOn = NO;
	fadeOutTrackButton.isOn = NO;

	if(button.isOn)
	{
		[OALSimpleAudio sharedInstance].bgVolume = 1.0f;
		[[OALSimpleAudio sharedInstance] playBg:@"ColdFunk.caf" loop:YES];
	}
	else
	{
		[[OALSimpleAudio sharedInstance] stopBg];
	}
}

- (void) onBackgroundFadeOut:(LampButton*) button
{
	fadeInTrackButton.isOn = NO;
	[[OALSimpleAudio sharedInstance].backgroundTrack stopFade];

	if([OALSimpleAudio sharedInstance].bgPlaying && [OALSimpleAudio sharedInstance].bgVolume > 0.0f)
	{
		if(button.isOn)
		{
			[[OALSimpleAudio sharedInstance].backgroundTrack fadeTo:0.0f duration:1.0f target:self selector:@selector(onBackgroundFadeComplete:)];
		}

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
	else
	{
		button.isOn = NO;
	}
}

- (void) onBackgroundFadeIn:(LampButton*) button
{
	fadeOutTrackButton.isOn = NO;
	[[OALSimpleAudio sharedInstance].backgroundTrack stopFade];
	
	if([OALSimpleAudio sharedInstance].bgPlaying && [OALSimpleAudio sharedInstance].bgVolume < 1.0f)
	{
		if(button.isOn)
		{
			[[OALSimpleAudio sharedInstance].backgroundTrack fadeTo:1.0f duration:1.0f target:self selector:@selector(onBackgroundFadeComplete:)];
		}

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
	else
	{
		button.isOn = NO;
	}
}

- (void) onBackgroundFadeComplete:(id) sender
{
	fadeInTrackButton.isOn = NO;
	fadeOutTrackButton.isOn = NO;
}


- (void) onObjectALPlayStop:(LampButton*) button
{
	[source stopFade];
	fadeInSourceButton.isOn = NO;
	fadeOutSourceButton.isOn = NO;
	
	if(button.isOn)
	{
		source = [[OALSimpleAudio sharedInstance] playEffect:@"HappyAlley.caf" loop:YES];
	}
	else
	{
		[source stop];
		source = nil;
	}
}

- (void) onObjectALFadeOut:(LampButton*) button
{
	fadeInSourceButton.isOn = NO;
	[source stopFade];
	
	if(nil != source && source.volume > 0.0f)
	{
		if(button.isOn)
		{
			[source fadeTo:0.0f duration:1.0f target:self selector:@selector(onObjectALFadeComplete:)];
		}

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
	else
	{
		button.isOn = NO;
	}
}

- (void) onObjectALFadeIn:(LampButton*) button
{
	fadeOutSourceButton.isOn = NO;
	[source stopFade];
	
	if(nil != source && source.volume < 1.0f)
	{
		if(button.isOn)
		{
			[source fadeTo:1.0f duration:1.0f target:self selector:@selector(onObjectALFadeComplete:)];
		}
		
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
	else
	{
		button.isOn = NO;
	}
}

- (void) onObjectALFadeComplete:(id) sender
{
	fadeInSourceButton.isOn = NO;
	fadeOutSourceButton.isOn = NO;
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
