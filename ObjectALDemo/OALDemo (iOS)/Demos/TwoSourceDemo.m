//
//  TwoSourceDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "TwoSourceDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "ImageButton.h"
#import <ObjectAL/ObjectAL.h>


#pragma mark Private Methods

@interface TwoSourceDemo (Private)

/** Exit the demo. */
- (void) onExitPressed;

@end


#pragma mark TwoSourceDemo

@implementation TwoSourceDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super init]))
	{
        SingleTouchableNode* touchLayer = [SingleTouchableNode node];
        touchLayer.contentSize = self.contentSize;
        [self addChild:touchLayer];
        touchLayer.isTouchEnabled = YES;

        __block TwoSourceDemo* blockSelf = self;
        touchLayer.onTouchStart = ^BOOL (CGPoint pos)
        {
            [blockSelf moveShipTo:pos];
            return NO;
        };

        touchLayer.onTouchMove =  ^BOOL (CGPoint pos)
        {
            [blockSelf moveShipTo:pos];
            return NO;
        };

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
		
		leftPlanet = [CCSprite spriteWithFile:@"Jupiter.png"];
		leftPlanet.position = ccp(40, center.y);
		[self addChild:leftPlanet];
		
		rightPlanet = [CCSprite spriteWithFile:@"Ganymede.png"];
		rightPlanet.position = ccp(size.width-40, center.y);
		[self addChild:rightPlanet];

		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];

		
	}
	return self;
}

- (void) dealloc
{
	[leftBuffer release];
	[leftSource release];
	[rightBuffer release];
	[rightSource release];

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
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
	
	leftSource = [[ALSource source] retain];
	// ColdFunk.caf is stereo, which doesn't work with positioning. Reduce to mono.
	leftBuffer = [[[OpenALManager sharedInstance] bufferFromFile:@"ColdFunk.caf" reduceToMono:YES] retain];
	
	rightSource = [[ALSource source] retain];
	// HappyAlley.caf is stereo, which doesn't work with positioning. Reduce to mono.
	rightBuffer = [[[OpenALManager sharedInstance] bufferFromFile:@"HappyAlley.caf" reduceToMono:YES] retain];
	
	leftSource.position = alpoint(leftPlanet.position.x, leftPlanet.position.y, 0);
	leftSource.referenceDistance = 50;
	
	rightSource.position = alpoint(rightPlanet.position.x, rightPlanet.position.y, 0);
	rightSource.referenceDistance = 50;
	
	[OpenALManager sharedInstance].currentContext.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
	
	// You can play with different distance models here if you want.
	// Models are explained in the OpenAL 1.1 specification, available at
	// http://connect.creativelabs.com/openal/Documentation
	[OpenALManager sharedInstance].currentContext.distanceModel = AL_EXPONENT_DISTANCE;
	//		context.distanceModel = AL_LINEAR_DISTANCE;
	//		leftSource.maxDistance = rightSource.maxDistance = 100;

	
	[leftSource play:leftBuffer loop:YES];
	[rightSource play:rightBuffer loop:YES];
}

- (void) onExitPressed
{
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
