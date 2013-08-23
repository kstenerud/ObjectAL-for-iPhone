//
//  MainLayer.m
//  ObjectALDemo
//
//  Created by Monkey on 7/09/12.
//

#import "MainLayer.h"

#import "SingleSourceDemo.h"
#import "TwoSourceDemo.h"
#import "VolumePitchPanDemo.h"
#import "CrossFadeDemo.h"
#import "PlanetKillerDemo.h"
#import "ChannelsDemo.h"
#import "FadeDemo.h"
#import "TargetedAction.h"
#import "AudioTrackDemo.h"
#import "HardwareDemo.h"
#import "AudioSessionDemo.h"
#import "ReverbDemo.h"
#import "SourceNotificationsDemo.h"
#import "IntroAndMainTrackDemo.h"
#import "HighSpeedPlaybackDemo.h"


#define kScenesPerPage 5

@interface IndexedMenuItemLabel: CCMenuItemLabel
{
	NSUInteger index;
}
@property(nonatomic,readwrite,assign) NSUInteger index;

@end

@implementation IndexedMenuItemLabel

@synthesize index;

@end



@interface MainLayer (Private)

- (void) prepareScenes;
- (void) addScene:(Class) sceneClass named:(NSString*) name;

- (void) setStartIndex:(int) newIndex;
- (void) onMenuSlideComplete;

- (void) onSceneSelect:(IndexedMenuItemLabel*) item;
- (void) onPrevious:(id) sender;
- (void) onNext:(id) sender;

@end

@implementation MainLayer

/** This is the index in the demo list where the main menu will start displaying from.
 * We keep this as a global so it maintains its value between scene changes.
 */
static int startIndex = 0;


-(id) init
{
	if(nil != (self = [super init]))
	{
		sceneNames = [[NSMutableArray arrayWithCapacity:20] retain];
		scenes = [[NSMutableArray arrayWithCapacity:20] retain];
		
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		CCLabelTTF* label;
		
		label = [CCLabelTTF labelWithString:@"Welcome to the ObjectAL demonstration." fontName:@"Helvetica" fontSize:20];
		label.position = ccp(screenSize.width/2, screenSize.height-18);
		[self addChild:label];
		
		label = [CCLabelTTF labelWithString:@"Select a demo to continue" fontName:@"Helvetica" fontSize:16];
		label.position = ccp(screenSize.width/2, screenSize.height-40);
		[self addChild:label];
		
		label = [CCLabelTTF labelWithString:@"______________________________" fontName:@"Helvetica" fontSize:28];
		label.color = ccc3(213, 199, 43);
		label.position = ccp(screenSize.width/2, screenSize.height-44);
		[self addChild:label];
		
		previousButton = [ImageButton buttonWithImageFile:@"Back.png" target:self selector:@selector(onPrevious:)];
		previousButton.position = ccp(previousButton.contentSize.width/2 + 10,
									  previousButton.contentSize.height/2);
		[self addChild:previousButton z:10];
		
		nextButton = [ImageButton buttonWithImageFile:@"Next.png" target:self selector:@selector(onNext:)];
		nextButton.position = ccp(screenSize.width - nextButton.contentSize.width/2 - 10,
								  nextButton.contentSize.height/2);
		[self addChild:nextButton z:10];
		
		label = [CCLabelTTF labelWithString:@"______________________________" fontName:@"Helvetica" fontSize:28];
		label.color = ccc3(213, 199, 43);
		label.position = ccp(screenSize.width/2, 64);
		[self addChild:label];
		
		label = [CCLabelTTF labelWithString:@"Tap arrows to switch pages" fontName:@"Helvetica" fontSize:16];
		label.position = ccp(screenSize.width/2, 26);
		[self addChild:label];
		
		
		[self prepareScenes];
		[self setStartIndex:startIndex];
	}
	return self;
}

- (void) dealloc
{
	[scenes release];
	[sceneNames release];
	[super dealloc];
}


- (void) prepareScenes
{
	[self addScene:[SingleSourceDemo class] named:@"Single Source (Positioning)"];
	[self addScene:[TwoSourceDemo class] named:@"Two Sources (Positioning)"];
	[self addScene:[VolumePitchPanDemo class] named:@"Volume, Pitch, and Pan"];
	[self addScene:[CrossFadeDemo class] named:@"Crossfade"];
	[self addScene:[ChannelsDemo class] named:@"Channels"];
	[self addScene:[FadeDemo class] named:@"Fading"];
	[self addScene:[ReverbDemo class] named:@"Reverb"];
	[self addScene:[AudioTrackDemo class] named:@"Audio Tracks"];
	[self addScene:[PlanetKillerDemo class] named:@"Planet Killer (OALSimpleAudio)"];
	[self addScene:[IntroAndMainTrackDemo class] named:@"Intro and Main Track"];
	[self addScene:[SourceNotificationsDemo class] named:@"Source Notifications"];
	[self addScene:[HardwareDemo class] named:@"Hardware Monitor"];
	[self addScene:[AudioSessionDemo class] named:@"Audio Sessions"];
	[self addScene:[HighSpeedPlaybackDemo class] named:@"High Speed Playback"];
}

- (void) addScene:(Class) sceneClass named:(NSString*) name
{
	[sceneNames addObject:name];
	[scenes addObject:sceneClass];
}

- (void) onEnterTransitionDidFinish
{
    // Note: I used to destroy and recreate OALSimpleAudio and friends, but
    // a bug in iOS 5 can cause the OpenAL device to not close when you tell it
    // to, so this is the next best thing I can do.

    // Restore some sensible defaults in case a demo changed it.

    [[OALSimpleAudio sharedInstance] stopAllEffects];
    [[OALAudioTracks sharedInstance] stopAllTracks];
	[OALSimpleAudio sharedInstance].reservedSources = 32;
    [OALSimpleAudio sharedInstance].context.listener.reverbOn = NO;
    [OALSimpleAudio sharedInstance].bgVolume = 1;
    [OALSimpleAudio sharedInstance].bgMuted = NO;
    [OALSimpleAudio sharedInstance].effectsVolume = 1;
    [OALSimpleAudio sharedInstance].effectsMuted = NO;
	[OpenALManager sharedInstance].currentContext.listener.position = alpoint(0, 0, 0);
}

- (void) setStartIndex:(int) newIndex
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float moveX = screenSize.width;
	if(newIndex > startIndex)
	{
		moveX = -moveX;
	}
	
	startIndex = newIndex;
	oldMenu = menu;
	
	previousButton.visible = previousButton.isTouchEnabled = startIndex > 0;
	nextButton.visible = nextButton.isTouchEnabled = startIndex < [scenes count] - kScenesPerPage;
	
	menu = [CCMenu menuWithItems:nil];
	int endIndex = startIndex + kScenesPerPage - 1;
	if(endIndex >= (int)[scenes count])
	{
		endIndex = (int)[scenes count] - 1;
	}
	for(int i = startIndex; i <= endIndex; i++)
	{
		IndexedMenuItemLabel* item = [IndexedMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:[sceneNames objectAtIndex:(NSUInteger)i]
                                                                                            fontName:@"Helvetica"
                                                                                            fontSize:30]
																  target:self
																selector:@selector(onSceneSelect:)];
		item.index = i;
		
		[menu addChild:item];
	}
	[menu alignItemsVertically];
	menu.position = ccp(menu.position.x, menu.position.y - 4);
	[self addChild:menu];
	
	if(nil != oldMenu)
	{
		menu.position = ccp(menu.position.x - moveX, menu.position.y);
		CCAction* action = [CCSequence actions:
							[CCSpawn actions:
							 [TargetedAction actionWithTarget:oldMenu action:
							  [CCMoveBy actionWithDuration:0.3f position:ccp(moveX,0)]],
							 [TargetedAction actionWithTarget:menu action:
							  [CCMoveBy actionWithDuration:0.3f position:ccp(moveX,0)]],
							 nil],
							[CCCallFunc actionWithTarget:self selector:@selector(onMenuSlideComplete)],
							nil];
#ifdef __CC_PLATFORM_IOS
		[[CCDirector sharedDirector] touchDispatcher].dispatchEvents = NO;
#elif defined(__CC_PLATFORM_MAC)
		[[CCDirector sharedDirector] eventDispatcher].dispatchEvents = NO;
#endif
		[self runAction:action];
	}
}

- (void) onMenuSlideComplete
{
	[oldMenu removeFromParentAndCleanup:YES];
	oldMenu = nil;

#ifdef __CC_PLATFORM_IOS
	[[CCDirector sharedDirector] touchDispatcher].dispatchEvents = YES;
#elif defined(__CC_PLATFORM_MAC)
	[[CCDirector sharedDirector] eventDispatcher].dispatchEvents = YES;
#endif
}

- (void) onSceneSelect:(IndexedMenuItemLabel*) item
{
	CCScene* scene = [[scenes objectAtIndex:item.index] scene];
	[[CCDirector sharedDirector] replaceScene:scene];
}

- (void) onPrevious:(__unused id) sender
{
	int newIndex = startIndex - kScenesPerPage;
	if(newIndex < 0)
	{
		newIndex = 0;
	}
	[self setStartIndex:newIndex];
}

- (void) onNext:(__unused id) sender
{
	int newIndex = startIndex + kScenesPerPage;
	if(newIndex >= (int)[scenes count])
	{
		newIndex = (int)[scenes count] - 1;
	}
	[self setStartIndex:newIndex];
}

@end
