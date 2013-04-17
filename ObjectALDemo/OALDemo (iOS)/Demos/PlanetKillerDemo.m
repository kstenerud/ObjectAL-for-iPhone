//
//  PlanetKillerDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "PlanetKillerDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "ImageButton.h"
#import "RNG.h"
#import <ObjectAL/ObjectAL.h>


#define SHOOT_SOUND @"Pew.caf"
#define EXPLODE_SOUND @"Pow.caf"


#pragma mark -
#pragma mark Private Methods

@interface PlanetKillerDemo (Private)

/** Point the ship. */
- (void) pointTo:(float) angleInRadians;

/** Shoot a bullet. */
- (void) shoot:(float) angleInRadians;

/** Remove a planet from the scene. */
- (void) removePlanet:(CCNode*) planet;

/** Remove a bullet from the scene. */
- (void) removeBullet:(CCNode*) bullet;

/** Game loop update method. */
- (void) onGameUpdate;

/** Add a planet to the scene. */
- (void) onAddPlanet;

/** Exit the demo. */
- (void) onExitPressed;

@end

#pragma mark -
#pragma mark PlanetKillerDemo

@implementation PlanetKillerDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super init]))
	{
        SingleTouchableNode* touchLayer = [SingleTouchableNode node];
        touchLayer.contentSize = self.contentSize;
        [self addChild:touchLayer];
        touchLayer.isTouchEnabled = YES;

        __block PlanetKillerDemo* blockSelf = self;
        touchLayer.onTouchStart = ^BOOL (CGPoint pos)
        {
            [blockSelf shoot:[self angleForPoint:pos]];
            return NO;
        };

        touchLayer.onTouchMove =  ^BOOL (CGPoint pos)
        {
            [blockSelf pointTo:[self angleForPoint:pos]];
            return NO;
        };

		// Build UI
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);

		CCLabelTTF* label = [CCLabelTTF labelWithString:@"Tap the screen to shoot!" fontName:@"Helvetica" fontSize:18];
		label.position = ccp(size.width/2, size.height-20);
		[self addChild:label];
		
		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];

		
		// Build game assets
		innerPlanetRect = CGRectMake(center.x - 50, center.y - 50, 100, 100);
		outerPlanetRect = CGRectMake(30, 30, size.width-60, size.height-60);

		ship = [CCSprite spriteWithFile:@"RocketShip.png"];
		ship.position = center;
		[self addChild:ship];
		
		planets = [[NSMutableArray arrayWithCapacity:20] retain];
		bullets = [[NSMutableArray arrayWithCapacity:20] retain];
		
		CCNode* planet = [CCSprite spriteWithFile:@"Jupiter.png"];
		impactDistanceSquared = planet.contentSize.width/2 * planet.contentSize.width/2;
	}
	return self;
}

- (void) dealloc
{
	[planets release];
	[bullets release];

	[super dealloc];
}


#pragma mark Utility

/** Point the ship.
 *
 * @param angleInRadians The angle to point the ship.
 */
- (void) pointTo:(float) angleInRadians
{
	ship.rotation = CC_RADIANS_TO_DEGREES(angleInRadians);
}


/** Build a bullet and shoot it 300 pixels in the specified direction.
 *
 * @param angleInRadians The angle to shoot at.
 */
- (void) shoot:(float) angleInRadians
{
	[self pointTo:angleInRadians];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);
	
	CGPoint initialPoint = ccp(center.x + sinf(angleInRadians)*50.0f,
							   center.y + cosf(angleInRadians)*50.0f);
	CGPoint endPoint = ccp(center.x + sinf(angleInRadians)*300.0f,
						   center.y + cosf(angleInRadians)*300.0f);
	
	CCSprite* bullet = [CCSprite spriteWithFile:@"Ganymede.png"];
	bullet.scale = 0.3f;
	bullet.position = initialPoint;
	[self addChild:bullet];
	[bullets addObject:bullet];
	
	CCActionInterval* action = [CCSequence actions:
								[CCMoveTo actionWithDuration:1.0f position:endPoint],
								[CCCallFuncN actionWithTarget:self selector:@selector(removeBullet:)],
								nil];
	[bullet runAction:action];
	[[OALSimpleAudio sharedInstance] playEffect:SHOOT_SOUND];
}


- (void) removePlanet:(CCNode*) planet
{
	[planets removeObject:planet];
	[self removeChild:planet cleanup:YES];
}


- (void) removeBullet:(CCNode*) bullet
{
	[bullets removeObject:bullet];
	[self removeChild:bullet cleanup:YES];
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	[[OALSimpleAudio sharedInstance] preloadEffect:SHOOT_SOUND];
	[[OALSimpleAudio sharedInstance] preloadEffect:EXPLODE_SOUND];
	[[OALSimpleAudio sharedInstance] playBg:@"PlanetKiller.mp3" loop:YES];

	self.isTouchEnabled = YES;
	[self schedule:@selector(onAddPlanet) interval:0.2f];
	[self schedule:@selector(onGameUpdate)];
}


/** Game loop.
 * Check for bullet collisions with planets.
 */
- (void) onGameUpdate
{
	CCNode* bulletToRemove = nil;
	CCNode* planetToRemove = nil;

	// Naive collision detection algorithm
	for(CCNode* bullet in bullets)
	{
		for(CCNode* planet in planets)
		{
			float xDistance = planet.position.x - bullet.position.x;
			float yDistance = planet.position.y - bullet.position.y;
			if(xDistance * xDistance + yDistance * yDistance < impactDistanceSquared)
			{
				bulletToRemove = bullet;
				planetToRemove = planet;
				break;
			}
		}
		if(nil != bulletToRemove)
		{
			break;
		}
	}
	if(nil != bulletToRemove)
	{
		[self removeBullet:bulletToRemove];
		[self removePlanet:planetToRemove];
		[[OALSimpleAudio sharedInstance] playEffect:EXPLODE_SOUND];
	}
}

/** Add a planet to a random location on the screen in between the inner
 * and outer bounds.
 * The planet fades in, remains for awhile, then fades out.
 */
- (void) onAddPlanet
{
	float rangeX = (innerPlanetRect.origin.x - outerPlanetRect.origin.x) * 2;
	float rangeY = (innerPlanetRect.origin.y - outerPlanetRect.origin.y) * 2;
	
	float randomX = [[RNG sharedInstance] randomNumberFrom:0 to:(int)rangeX];
	float randomY = [[RNG sharedInstance] randomNumberFrom:0 to:(int)rangeY];
	
	CGPoint position = ccp(randomX+outerPlanetRect.origin.x, randomY+outerPlanetRect.origin.y);
	if(position.x > innerPlanetRect.origin.x)
	{
		position.x += innerPlanetRect.size.width;
	}
	if(position.y > innerPlanetRect.origin.y)
	{
		position.y += innerPlanetRect.size.height;
	}
	
	CCSprite* planet = [CCSprite spriteWithFile:@"Jupiter.png"];
	planet.position = position;
	planet.opacity = 0;
	[self addChild:planet];
	[planets addObject:planet];
	
	CCSequence* action = [CCSequence actions:
						  [CCFadeIn actionWithDuration:0.5f],
						  [CCDelayTime actionWithDuration:3.0f],
						  [CCFadeOut actionWithDuration:0.5f],
						  [CCCallFuncN actionWithTarget:self selector:@selector(removePlanet:)],
						  nil];
	[planet runAction:action];
}


- (void) onExitPressed
{
	[self unschedule:@selector(onAddPlanet)];
	[self unschedule:@selector(onGameUpdate)];
	self.isTouchEnabled = NO;
	[[OALSimpleAudio sharedInstance] stopEverything];
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (float) angleForPoint:(CGPoint) point
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    CGPoint center = ccp(size.width/2, size.height/2);

    float angle = (float)M_PI/2 - atanf((point.y - center.y) / (point.x - center.x));
    if(point.x < center.x)
    {
        angle = (float)M_PI + angle;
    }

    return angle;
}

@end
