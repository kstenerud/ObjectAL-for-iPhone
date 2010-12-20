//
//  OALSuspendHandler.h
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

#import <Foundation/Foundation.h>

/**
 * Allows an object to participate in interrupt and suspend operations.
 * Objects may hook into OALAudioSession's interrupt and suspend model by
 * calling [[OALAudioSession sharedInstance] addSuspendListener:self].
 *
 * Note: You must NOT set the "interrupted" property manually. It is designed
 *       to be set automatically by system interrupts.
 *
 * @see OALAudioSession
 */
@protocol OALSuspendListener

/** Set to YES to manually suspend.
 */
@property(readwrite,assign) bool manuallySuspended;

/** If YES, this object is interrupted.
 * Note: This property must NOT be set by the user!
 */
@property(readwrite,assign) bool interrupted;

@end


/**
 * A suspend manager is a listener that also allows other objects
 * to subscribe to receive events as the manager receives them.
 */
@protocol OALSuspendManager <OALSuspendListener>

/** If YES, this object is suspended.
 */
@property(readonly) bool suspended;

/** Add a listener that will receive manual suspend and interrupt events.
 *
 * @param listener The listener to register with this handler.
 */
- (void) addSuspendListener:(id<OALSuspendListener>) listener;

/** Remove a registered listener.
 *
 * @param listener The listener to unregister from this handler.
 */
- (void) removeSuspendListener:(id<OALSuspendListener>) listener;

@end


/**
 * Provides two controls (interrupted and manuallySuspended) for suspending
 * a slave object, and also propagates such control messages to interested
 * listeners.
 *
 * "interrupted" is meant to be set by the system when an interrupt occurs. <br>
 *
 * "manuallySuspended" is a user-settable control for suspending an object. <br>
 * "manuallySuspended" also has an extra step in its processing: When set,
 * the handler makes a note of what its listeners' "manuallySuspended" values are.
 * When cleared, it will only clear a listener's "manuallySuspended" value if it
 * was not set at suspend time. This allows for ad-hoc setting/clearing of
 * "manuallySuspended" in the middle of a handler/listener graph rather than
 * only from the top level. <br>
 *
 * When either control is set, the slave object will be suspended.  When both are
 * cleared, the slave object will be unsuspended. <br>
 */
@interface OALSuspendHandler: NSObject
{
	/** Listeners that will receive manualSuspend and interrupt events. */
	NSMutableArray* listeners;
	
	/** Holder for the state of manualSuspend in listeners when this object is
	 * manually suspended.
	 */
	NSMutableArray* manualSuspendStates;
	
	/** Slave object that is notified when this object suspends or unsuspends. */
	id suspendStatusChangeTarget;
	
	/** Selector to be invoked on suspend or unsuspend.
	 * Takes the signature: setSelected:(bool) value
	 */
	SEL suspendStatusChangeSelector;
	
	/** Holds the current "manually suspended" state. */
	bool manualSuspendLock;
	
	/** Holds the current "interrupted" state. */
	bool interruptLock;
}

/** Create a new handler with the specified slave target and selector.
 *
 * The selector provided must take a single boolean value like so: <br>
 * - (void) setSuspended:(bool) value <br>
 *
 * @param target The slave object that will receive suspend/unsuspend events.
 * @param selector The selector for a "set suspended" method, taking a single
 *                 boolean parameter.
 */
+ (OALSuspendHandler*) handlerWithTarget:(id) target selector:(SEL) selector;

/** Initialize a handler with the specified slave target and selector.
 *
 * The selector provided must take a single boolean value like so: <br>
 * - (void) setSuspended:(bool) value <br>
 *
 * @param target The slave object that will receive suspend/unsuspend events.
 * @param selector The selector for a "set suspended" method, taking a single
 *                 boolean parameter.
 */
- (id) initWithTarget:(id) target selector:(SEL) selector;


/** If YES, the manual suspend control is set. */
@property(readwrite,assign) bool manuallySuspended;

/** If YES, the interrupt control is set. */
@property(readwrite,assign) bool interrupted;

/** If YES, the slave object is suspended. */
@property(readonly) bool suspended;

/** Add a listener that will receive manual suspend and interrupt events.
 *
 * @param listener The listener to register with this handler.
 */
- (void) addSuspendListener:(id<OALSuspendListener>) listener;

/** Remove a registered listener.
 *
 * @param listener The listener to unregister from this handler.
 */
- (void) removeSuspendListener:(id<OALSuspendListener>) listener;

@end
