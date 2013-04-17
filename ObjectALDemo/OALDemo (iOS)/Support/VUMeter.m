//
//  VUMeter.m
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "VUMeter.h"

#define kMinRotation -50
#define kMaxRotation 25
#define kRotationRange (kMaxRotation - kMinRotation)

#define kDefaultSmoothing 0.1
#define kDefaultMultiplier 2.0


@implementation VUMeter

+ (VUMeter*) meter
{
	return [[[self alloc] init] autorelease];
}

- (id) init
{
	if(nil != (self = [super init]))
	{
		CCSprite* shell = [CCSprite spriteWithFile:@"vu-shell.png"];
		shell.anchorPoint = ccp(0,0);
		shell.position = ccp(0, 0);
		[self addChild:shell z:10];
		
		CCSprite* face = [CCSprite spriteWithFile:@"vu-face.png"];
		face.anchorPoint = ccp(0,0);
		face.position = ccp(0, 0);
		[self addChild:face z:0];
		
		needle = [CCSprite spriteWithFile:@"vu-needle.png"];
		needle.anchorPoint = ccp(0.5f, 0);
		needle.position = ccp(64, 56);
		[self addChild:needle];
		
		smoothing = kDefaultSmoothing;
		multiplier = kDefaultMultiplier;
		
		self.contentSize = shell.contentSize;
		self.db = -160;
	}
	return self;
}

- (double) db
{
	return db;
}

- (void) setDb:(double) value
{
	db = value;
	double normalized = pow(10, (0.05 * db)) * multiplier;
	runningAverage = smoothing * normalized + (1.0 - smoothing) * runningAverage;
	
	needle.rotation = (float)(kMinRotation + runningAverage * kRotationRange);
}

@synthesize runningAverage;
@synthesize smoothing;
@synthesize multiplier;

@end
