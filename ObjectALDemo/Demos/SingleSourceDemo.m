//
//  SingleSourceDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "SingleSourceDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "ImageButton.h"
#import "ObjectAL.h"


#pragma mark Private Methods

@interface SingleSourceDemo (Private)

/** Exit the demo. */
- (void) onExitPressed;

@end


#pragma mark SingleSourceDemo

@implementation SingleSourceDemo

#pragma mark Object Management

-(id) init
{
	if(nil != (self = [super init]))
	{
		// Build UI
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);

		CCLabelTTF* label = [CCLabelTTF labelWithString:@"Drag the ship around" fontName:@"Helvetica" fontSize:20];
		label.position = ccp(size.width/2, size.height-30);
		[self addChild:label];
		
		label = [CCLabelTTF labelWithString:@"(Works best with headphones on)" fontName:@"Helvetica" fontSize:20];
		label.position = ccp(size.width/2, size.height-60);
		[self addChild:label];
		
		rocketShip = [CCSprite spriteWithFile:@"RocketShip.png"];
		rocketShip.position = ccp(center.x, center.y - 50);
		[self addChild:rocketShip z:20];

		planet = [CCSprite spriteWithFile:@"Jupiter.png"];
		planet.position = center;
		[self addChild:planet];
		
		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];
	}
	return self;
}

- (void) dealloc
{
	[source stop];
	[source release];
	[buffer release];

	[super dealloc];
}


#pragma mark Utility

- (void) moveShipTo:(CGPoint) position
{
	rocketShip.position = position;
	[OpenALManager sharedInstance].currentContext.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	// Initialize the OpenAL device and context here so that it doesn't happen
	// prematurely.
	
	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	source = [[ALSource source] retain];
	
	// ColdFunk.caf is stereo, which doesn't work with positioning. Reduce to mono.
	buffer = [[[OpenALManager sharedInstance] bufferFromFile:@"ColdFunk.caf" reduceToMono:YES] retain];
	
	source.position = alpoint(planet.position.x, planet.position.y, 0);
	//		source.maxDistance = 300;
	source.referenceDistance = 50;
	
	[OpenALManager sharedInstance].currentContext.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
	
	self.isTouchEnabled = YES;
	[source play:buffer loop:YES];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    [self moveShipTo:[self convertTouchToNodeSpace:[touches anyObject]]];
}

- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
    [self moveShipTo:[self convertTouchToNodeSpace:[touches anyObject]]];
}

@end
