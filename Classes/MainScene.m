//
//  MainLayer.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "MainScene.h"
#import "CCLayer+Scene.h"
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


#define kScenesPerPage 5

@interface IndexedMenuItemLabel: CCMenuItemLabel
{
	int index;
}
@property(readwrite,assign) int index;

@end

@implementation IndexedMenuItemLabel

@synthesize index;

@end



@interface MainLayer (Private)

- (void) prepareScenes;
- (void) addScene:(Class) sceneClass named:(NSString*) name;

- (void) setStartIndex:(uint) newIndex;
- (void) onMenuSlideComplete;

- (void) onSceneSelect:(IndexedMenuItemLabel*) item;
- (void) onPrevious:(id) sender;
- (void) onNext:(id) sender;

@end

@implementation MainLayer

/** This is the index in the demo list where the main menu will start displaying from.
 * We keep this as a global so it maintains its value between scene changes.
 */
static uint startIndex = 0;


-(id) init
{
	if(nil != (self = [super init]))
	{
		sceneNames = [[NSMutableArray arrayWithCapacity:20] retain];
		scenes = [[NSMutableArray arrayWithCapacity:20] retain];
		
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		CCLabel* label;
		
		label = [CCLabel labelWithString:@"Welcome to the ObjectAL demo." fontName:@"Helvetica" fontSize:20];
		label.position = ccp(screenSize.width/2, screenSize.height-18);
		[self addChild:label];
		
		label = [CCLabel labelWithString:@"Select a menu item to continue" fontName:@"Helvetica" fontSize:16];
		label.position = ccp(screenSize.width/2, screenSize.height-40);
		[self addChild:label];
		
		label = [CCLabel labelWithString:@"______________________________" fontName:@"Helvetica" fontSize:28];
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
		
		label = [CCLabel labelWithString:@"______________________________" fontName:@"Helvetica" fontSize:28];
		label.color = ccc3(213, 199, 43);
		label.position = ccp(screenSize.width/2, 64);
		[self addChild:label];
		
		label = [CCLabel labelWithString:@"Tap arrows to switch pages" fontName:@"Helvetica" fontSize:16];
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
	[self addScene:[AudioTrackDemo class] named:@"Audio Tracks"];
	[self addScene:[PlanetKillerDemo class] named:@"Planet Killer (OALSimpleAudio)"];
	[self addScene:[HardwareDemo class] named:@"Hardware Monitor"];
}

- (void) addScene:(Class) sceneClass named:(NSString*) name
{
	[sceneNames addObject:name];
	[scenes addObject:sceneClass];
}

- (void) onEnterTransitionDidFinish
{
	/* Make sure OALSimpleAudio isn't initialized from another demo
	 * when returning to the main scene.
	 *
	 * Note: You normally wouldn't do this in a real project. I do it here
	 * to provide a clean slate for the individual demos, which expect a
	 * clean slate.
	 */
	[OALSimpleAudio purgeSharedInstance];
}

- (void) setStartIndex:(uint) newIndex
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
	nextButton.visible = nextButton.isTouchEnabled = startIndex < [scenes count] - kScenesPerPage - 1;
	
	menu = [CCMenu menuWithItems:nil];
	uint endIndex = startIndex + kScenesPerPage - 1;
	if(endIndex >= [scenes count])
	{
		endIndex = [scenes count] - 1;
	}
	for(uint i = startIndex; i <= endIndex; i++)
	{
		IndexedMenuItemLabel* item = [IndexedMenuItemLabel itemWithLabel:[CCLabel labelWithString:[sceneNames objectAtIndex:i]
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
		[CCTouchDispatcher sharedDispatcher].dispatchEvents = NO;
		[self runAction:action];
	}
}

- (void) onMenuSlideComplete
{
	[oldMenu removeFromParentAndCleanup:YES];
	oldMenu = nil;

	[CCTouchDispatcher sharedDispatcher].dispatchEvents = YES;
}

- (void) onSceneSelect:(IndexedMenuItemLabel*) item
{
	CCScene* scene = [[scenes objectAtIndex:item.index] scene];
	[[CCDirector sharedDirector] replaceScene:scene];
}

- (void) onPrevious:(id) sender
{
	int newIndex = startIndex - kScenesPerPage;
	if(newIndex < 0)
	{
		newIndex = 0;
	}
	[self setStartIndex:newIndex];
}

- (void) onNext:(id) sender
{
	uint newIndex = startIndex + kScenesPerPage;
	if(newIndex >= [scenes count])
	{
		newIndex = [scenes count] - 1;
	}
	[self setStartIndex:newIndex];
}

@end
