//
//  TargetedAction.m
//  MouseMadness
//
//  Created by Karl Stenerud on 09-12-24.
//

#import "TargetedAction.h"

@interface TargetedAction (Private)

// Ugly hack to get around a compiler bug.
- (id) initWithTarget:(id) targetIn actionByAnotherName:(CCFiniteTimeAction*) actionIn;

@end


@implementation TargetedAction

@synthesize forcedTarget;

+ (id) actionWithTarget:(id) target action:(CCFiniteTimeAction*) action
{
	return [[[self alloc] initWithTarget:target actionByAnotherName:action] autorelease];
}

- (id) initWithTarget:(id) targetIn action:(CCFiniteTimeAction*) actionIn
{
	return [self initWithTarget:targetIn actionByAnotherName:actionIn];
}

- (id) initWithTarget:(id) targetIn actionByAnotherName:(CCFiniteTimeAction*) actionIn
{
	if(nil != (self = [super initWithDuration:actionIn.duration]))
	{
		forcedTarget = [targetIn retain];
		action = [actionIn retain];
	}
	return self;
}

- (void) dealloc
{
	[forcedTarget release];
	[action release];
	[super dealloc];
}

- (void) startWithTarget:(__unused id)aTarget
{
	[super startWithTarget:forcedTarget];
	[action startWithTarget:forcedTarget];
}

- (void) stop
{
	[action stop];
}

- (void) update:(ccTime) time
{
	[action update:time];
}

@end
