//
//  OALSuspendHandler.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-12-19.
//
// Copyright 2010 Karl Stenerud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Note: You are NOT required to make the license available from within your
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALSuspendHandler.h"
#import "NSMutableArray+WeakReferences.h"
#import <objc/message.h>

@implementation OALSuspendHandler

+ (OALSuspendHandler*) handlerWithTarget:(id) target selector:(SEL) selector
{
	return [[[self alloc] initWithTarget:target selector:selector] autorelease];
}

- (id) initWithTarget:(id) target selector:(SEL) selector
{
	if(nil != (self = [super init]))
	{
		listeners = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:10];
		manualSuspendStates = [[NSMutableArray alloc] initWithCapacity:10];
		suspendStatusChangeTarget = target;
		suspendStatusChangeSelector = selector;
	}
	return self;
}

- (void) dealloc
{
	[listeners release];
	[manualSuspendStates release];

	[super dealloc];
}

- (void) addSuspendListener:(id<OALSuspendListener>) listener
{
	@synchronized(self)
	{
		[listeners addObject:listener];
		// If this handler is already suspended, make sure we don't unsuspend
		// a newly added listener on the next manual unsuspend.
		bool startingSuspendedValue = manualSuspendLock ? listener.manuallySuspended : NO;
		[manualSuspendStates addObject:[NSNumber numberWithBool:startingSuspendedValue]];
	}
}

- (void) removeSuspendListener:(id<OALSuspendListener>) listener
{
	@synchronized(self)
	{
		NSUInteger index = [listeners indexOfObject:listener];
		if(NSNotFound != index)
		{
			[listeners removeObjectAtIndex:index];
			[manualSuspendStates removeObjectAtIndex:index];
		}
	}
}

- (bool) manuallySuspended
{
	@synchronized(self)
	{
		return manualSuspendLock;
	}
}

- (void) setManuallySuspended:(bool) value
{
	/* This handler propagates all suspend/unsuspend events to all listeners.
	 * An unsuspend will occur in the reverse order to a suspend (meaning, it will
	 * unsuspend listeners in the reverse order that it suspended them).
	 * On suspend, all listeners will be suspended prior to suspending this handler's
	 * slave object. On unsuspend, all listeners will resume after the slave object.
	 *
	 * Since "suspended" is manually triggered, this handler records all listeners'
	 * suspend states so that it can intelligently decide whether to unsuspend or
	 * not.
	 */
	
	@synchronized(self)
	{
		// Setting must occur in the opposite order to clearing.
		if(value)
		{
			NSUInteger numListeners = [listeners count];
			for(NSUInteger index = 0; index < numListeners; index++)
			{
				id<OALSuspendListener> listener = [listeners objectAtIndex:index];
				
				// Record whether they were already suspended or not
				bool alreadySuspended = listener.manuallySuspended;
				if(alreadySuspended != [[manualSuspendStates objectAtIndex:index] boolValue])
				{
					[manualSuspendStates replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:alreadySuspended]];
				}
				
				// Update listener suspend state if necessary
				if(!alreadySuspended)
				{
					listener.manuallySuspended = YES;
				}
			}
		}

		/* If the new value is the same as the old, do nothing.
		 * If the other lock is set, do nothing.
		 * Otherwise, send a suspend/unsuspend event to the slave.
		 */
		if(value != manualSuspendLock)
		{
			manualSuspendLock = value;
			if(!interruptLock)
			{
				if(nil != suspendStatusChangeTarget)
				{
					objc_msgSend(suspendStatusChangeTarget, suspendStatusChangeSelector, manualSuspendLock);
				}
			}
		}
		
		// Ensure clearing occurs in opposing order
		if(!value)
		{
			for(int index = (int)[listeners count] - 1; index >= 0; index--)
			{
				id<OALSuspendListener> listener = [listeners objectAtIndex:index];
				
				bool alreadySuspended = [[manualSuspendStates objectAtIndex:index] boolValue];
				
				// Update listener suspend state if necessary
				if(!alreadySuspended && listener.manuallySuspended)
				{
					listener.manuallySuspended = NO;
				}
			}
		}
	}
}

- (bool) interrupted
{
	@synchronized(self)
	{
		return interruptLock;
	}
}

- (void) setInterrupted:(bool) value
{
	/* This handler propagates all interrupt/end interrupt events to all listeners.
	 * An end interrupt will occur in the reverse order to an interrupt (meaning, it will
	 * end interrupt on listeners in the reverse order that it interrupted them).
	 * On interrupt, all listeners will be interrupted prior to suspending this handler's
	 * slave object. On end interrupt, all listeners will end interrupt after the slave object.
	 */
	@synchronized(self)
	{
		// Setting must occur in the opposite order to clearing.
		if(value)
		{
			for(id<OALSuspendListener> listener in listeners)
			{
				if(!listener.interrupted)
				{
					listener.interrupted = YES;
				}
			}
		}
		
		/* If the new value is the same as the old, do nothing.
		 * If the other lock is set, do nothing.
		 * Otherwise, send a suspend/unsuspend event to the slave.
		 */
		if(value != interruptLock)
		{
			interruptLock = value;
			if(!manualSuspendLock)
			{
				if(nil != suspendStatusChangeTarget)
				{
					objc_msgSend(suspendStatusChangeTarget, suspendStatusChangeSelector, interruptLock);
				}
			}
		}
		
		// Ensure clearing occurs in opposing order
		if(!value)
		{
			for(id<OALSuspendListener> listener in [listeners reverseObjectEnumerator])
			{
				if(listener.interrupted)
				{
					listener.interrupted = NO;
				}
			}
		}
	}
}

- (bool) suspended
{
	return interruptLock | manualSuspendLock;
}

@end
