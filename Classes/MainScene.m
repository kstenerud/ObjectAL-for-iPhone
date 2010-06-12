//
//  MainLayer.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "MainScene.h"
#import "SingleSourceDemo.h"
#import "TwoSourceDemo.h"
#import "VolumePitchPanDemo.h"
#import "CrossFadeDemo.h"
#import "PlanetKillerDemo.h"
#import "ChannelsDemo.h"


@implementation MainLayer

+(id) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [self node]];
	return scene;
}

-(id) init
{
	if(nil != (self = [super init]))
	{
		CCMenu* menu = [CCMenu menuWithItems:
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Single Source (Positioning)" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onSingle)],
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Two Sources (Positioning)" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onTwo)],
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Volume, Pitch, and Pan" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onFadeAndVolume)],
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Crossfade" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onCrossfade)],
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Channels" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onChannels)],
						[CCMenuItemLabel itemWithLabel:[CCLabel labelWithString:@"Planet Killer (SimpleIphoneAudio)" fontName:@"Helvetica" fontSize:30] target:self selector:@selector(onPlanetKiller)],
						nil];
		[menu alignItemsVertically];
		[self addChild:menu];
	}
	return self;
}

- (void) onSingle
{
	[[CCDirector sharedDirector] replaceScene:[SingleSourceDemo scene]];
}

- (void) onTwo
{
	[[CCDirector sharedDirector] replaceScene:[TwoSourceDemo scene]];
}

- (void) onFadeAndVolume
{
	[[CCDirector sharedDirector] replaceScene:[VolumePitchPanDemo scene]];
}

- (void) onCrossfade
{
	[[CCDirector sharedDirector] replaceScene:[CrossFadeDemo scene]];
}

- (void) onPlanetKiller
{
	[[CCDirector sharedDirector] replaceScene:[PlanetKillerDemo scene]];
}

- (void) onChannels
{
	[[CCDirector sharedDirector] replaceScene:[ChannelsDemo scene]];
}

@end
