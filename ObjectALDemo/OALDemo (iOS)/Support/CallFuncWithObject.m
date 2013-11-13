//
//  CallFuncWithObject.m
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "CallFuncWithObject.h"


@implementation CallFuncWithObject

+ (id) actionWithTarget:(id)target
			   selector:(SEL)selector
				 object:(id) object
{
	return [[[self alloc] initWithTarget:target selector:selector object:object] autorelease];
}

+ (id) actionWithTarget:(id)target
			   selector:(SEL)selector
				 object:(id) object
				 object:(id) object2
{
	return [[[self alloc] initWithTarget:target selector:selector object:object object:object2] autorelease];
}

- (id) initWithTarget:(id)targetIn
			 selector:(SEL)selectorIn
			   object:(id) objectIn
{
	if(nil != (self = [super initWithTarget:targetIn selector:selectorIn]))
	{
		object = [objectIn retain];
		twoObjects = NO;
	}
	return self;
}

- (id) initWithTarget:(id)targetIn
			 selector:(SEL)selectorIn
			   object:(id) objectIn
			   object:(id) object2In
{
	if(nil != (self = [super initWithTarget:targetIn selector:selectorIn]))
	{
		object = [objectIn retain];
		object2 = [object2In retain];
		twoObjects = YES;
	}
	return self;
}

- (void) dealloc
{
	[object release];
	[object2 release];
	[super dealloc];
}

-(void) execute
{
	if(twoObjects)
	{
		[_targetCallback performSelector:_selector withObject:object withObject:object2];
	}
	else
	{
		[_targetCallback performSelector:_selector withObject:object];
	}
}

@end
