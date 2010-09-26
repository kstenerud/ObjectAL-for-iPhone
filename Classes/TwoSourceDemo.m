//
//  TwoSourceDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "TwoSourceDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "ImageButton.h"
#import "ObjectAL.h"


#pragma mark TwoSourceDemo

@implementation TwoSourceDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Build UI
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);
		
		rocketShip = [CCSprite spriteWithFile:@"RocketShip.png"];
		rocketShip.position = ccp(center.x, center.y - 50);
		[self addChild:rocketShip z:20];
		
		CCSprite* leftPlanet = [CCSprite spriteWithFile:@"Jupiter.png"];
		leftPlanet.position = ccp(40, center.y);
		[self addChild:leftPlanet];
		
		CCSprite* rightPlanet = [CCSprite spriteWithFile:@"Ganymede.png"];
		rightPlanet.position = ccp(size.width-40, center.y);
		[self addChild:rightPlanet];

		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];

		
		// Initialize ObjectAL
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[OpenALManager sharedInstance].currentContext = context;
		
		[IphoneAudioSupport sharedInstance].handleInterruptions = YES;
		
		leftSource = [[ALSource source] retain];
		leftBuffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"ColdFunk.wav"] retain];
		
		rightSource = [[ALSource source] retain];
		rightBuffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"HappyAlley.wav"] retain];
		
		leftSource.position = alpoint(leftPlanet.position.x, leftPlanet.position.y, 0);
		leftSource.referenceDistance = 50;
		
		rightSource.position = alpoint(rightPlanet.position.x, rightPlanet.position.y, 0);
		rightSource.referenceDistance = 50;

		context.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
		
		// You can play with different distance models here if you want.
		// Models are explained in the OpenAL 1.1 specification, available at
		// http://connect.creativelabs.com/openal/Documentation
		context.distanceModel = AL_EXPONENT_DISTANCE;
//		context.distanceModel = AL_LINEAR_DISTANCE;
//		leftSource.maxDistance = rightSource.maxDistance = 100;
	}
	return self;
}

- (void) dealloc
{
	[leftBuffer release];
	[leftSource release];
	[rightBuffer release];
	[rightSource release];

	// Note: Normally you wouldn't release the context and device when leaving a scene.
	// I'm doing it here to provide a clean slate for the other demos.
	[context release];
	[device release];

	[super dealloc];
}


#pragma mark Utility

- (void) moveShipTo:(CGPoint) position
{
	rocketShip.position = position;
	context.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
}


#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
	self.isTouchEnabled = YES;
	[leftSource play:leftBuffer loop:YES];
	[rightSource play:rightBuffer loop:YES];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	
	if( touch ) {
		// Landscape mode, so Y is really X, with 0 = left.
		// X is really Y, with 0 = bottom.  Subtract from 320 to put 0 = top.
		
		CGPoint location = ccp([touch locationInView:[touch view]].y, [touch locationInView:[touch view]].x);
		[self moveShipTo:location];
	}
}

- (void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	
	if( touch ) {
		// Landscape mode, so Y is really X, with 0 = left.
		// X is really Y, with 0 = bottom.  Subtract from 320 to put 0 = top.
		
		CGPoint location = ccp([touch locationInView:[touch view]].y, [touch locationInView:[touch view]].x);
		[self moveShipTo:location];
	}
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	
	if( touch ) {
		// Landscape mode, so Y is really X, with 0 = left.
		// X is really Y, with 0 = bottom.  Subtract from 320 to put 0 = top.
		
		CGPoint location = ccp([touch locationInView:[touch view]].y, [touch locationInView:[touch view]].x);
		[self moveShipTo:location];
	}
}

@end
