//
//  SingleSourceDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "SingleSourceDemo.h"
#import "IphoneAudioSupport.h"
#import "ImageButton.h"
#import "MainScene.h"


#pragma mark SingleSourceDemo

@implementation SingleSourceDemo

#pragma mark Object Management

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
		// Build UI
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint center = ccp(size.width/2, size.height/2);

		rocketShip = [CCSprite spriteWithFile:@"RocketShip.png"];
		rocketShip.position = ccp(center.x, center.y - 50);
		[self addChild:rocketShip z:20];

		CCSprite* planet = [CCSprite spriteWithFile:@"Jupiter.png"];
		planet.position = center;
		[self addChild:planet];
		
		ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
		button.anchorPoint = ccp(1,1);
		button.position = ccp(size.width, size.height);
		[self addChild:button z:250];


		// Initialize ObjectAL
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[ObjectAL sharedInstance].currentContext = context;
		
		[IphoneAudioSupport sharedInstance].handleInterruptions = YES;
		
		source = [[ALSource source] retain];
		buffer = [[[IphoneAudioSupport sharedInstance] bufferFromFile:@"ColdFunk.wav"] retain];
		
		source.position = alpoint(planet.position.x, planet.position.y, 0);
		//		source.maxDistance = 300;
		source.referenceDistance = 50;
		
		context.listener.position = alpoint(rocketShip.position.x, rocketShip.position.y, 0);
	}
	return self;
}

- (void) dealloc
{
	[source stop];
	[source release];
	[buffer release];

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
	[source play:buffer loop:YES];
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
