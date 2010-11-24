//
//  SuspendLock.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-11-20.
//

#import <Foundation/Foundation.h>


/**
 * Implements a double-locking mechanism, consisting of a user controled 
 * "suspend" lock and a system controlled "interrupt" lock.
 *
 * When either lock is set, the mechanism locks. <br>
 * When both are cleared, the mechanism unlocks. <br>
 * If either is set, setting or clearing the other has no effect. <br>
 *
 * When the mechanism locks or unlocks, it invokes a selector on the
 * target provided during lock creation.
 */
@interface SuspendLock : NSObject
{
	bool interruptLock;
	bool suspendLock;

	/** The target to be invoked on lock/unlock */
	id target;
	/** The selector to call when locking */
	SEL lockSelector;
	/** The selector to call when unlocking */
	SEL unlockSelector;
}

/** If true, the "interrupt" lock is set */
@property(readwrite,assign) bool interruptLock;

/** If true, the "suspend" lock is set */
@property(readwrite,assign) bool suspendLock;

/** If true, the mechanism is locked */
@property(readonly) bool locked;

/**
 * Create a lock.
 *
 * @param target The target to inform of locks/unlocks.
 * @param lockSelector The selector to invoke upon a lock.
 * @param unlockSelector The selector to invoke upon an unlock.
 * @return A lock.
 */
+ (SuspendLock*) lockWithTarget:(id) target
				   lockSelector:(SEL) lockSelector
				 unlockSelector:(SEL) unlockSelector;

/**
 * Initialize a lock.
 *
 * @param target The target to inform of locks/unlocks.
 * @param lockSelector The selector to invoke upon a lock.
 * @param unlockSelector The selector to invoke upon an unlock.
 * @return The initialized lock.
 */
- (id) initWithTarget:(id) target
		 lockSelector:(SEL) lockSelector
	   unlockSelector:(SEL) unlockSelector;

@end
