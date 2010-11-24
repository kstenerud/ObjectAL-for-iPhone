//
//  DoubleLock.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-11-20.
//

#import "SuspendLock.h"


@implementation SuspendLock

+ (SuspendLock*) lockWithTarget:(id) target
				   lockSelector:(SEL) lockSelector
				 unlockSelector:(SEL) unlockSelector
{
	return [[[self alloc] initWithTarget:target
							lockSelector:lockSelector
						  unlockSelector:unlockSelector] autorelease];
}

- (id) initWithTarget:(id) targetIn
		 lockSelector:(SEL) lockSelectorIn
	   unlockSelector:(SEL) unlockSelectorIn
{
	if(nil != (self = [super init]))
	{
		target = targetIn;
		lockSelector = lockSelectorIn;
		unlockSelector = unlockSelectorIn;
	}
	return self;
}

- (bool) interruptLock
{
	@synchronized(self)
	{
		return interruptLock;
	}
}

- (void) setInterruptLock:(bool) value
{
	/* If the new value is the same as the old, do nothing.
	 * If the other lock is set, do nothing.
	 * Otherwise, this lock performs a lock or unlock.
	 */
	@synchronized(self)
	{
		if(value != interruptLock)
		{
			interruptLock = value;
			if(!suspendLock)
			{
				if(interruptLock)
				{
					[target performSelector:lockSelector];
				}
				else
				{
					[target performSelector:unlockSelector];
				}
			}
		}
	}
}

- (bool) suspendLock
{
	@synchronized(self)
	{
		return suspendLock;
	}
}

- (void) setSuspendLock:(bool) value
{
	/* If the new value is the same as the old, do nothing.
	 * If the other lock is set, do nothing.
	 * Otherwise, this lock performs a lock or unlock.
	 */
	@synchronized(self)
	{
		if(value != suspendLock)
		{
			suspendLock = value;
			if(!interruptLock)
			{
				if(suspendLock)
				{
					[target performSelector:lockSelector];
				}
				else
				{
					[target performSelector:unlockSelector];
				}
			}
		}
	}
}

- (bool) locked
{
	@synchronized(self)
	{
		return suspendLock | interruptLock;
	}
}

@end
