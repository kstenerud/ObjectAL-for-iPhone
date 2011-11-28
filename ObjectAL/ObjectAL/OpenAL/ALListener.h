//
//  ALListener.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-07.
//
//  Copyright (c) 2009 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import "ALTypes.h"
#import "OALSuspendHandler.h"

@class ALContext;


#pragma mark ALListener

/**
 * The listener represents the user who is listening to sounds in 3D space.
 * This object controls his position, orientation, and velocity, as well as providing a master
 * gain. <br>
 * A context contains one and only one listener.
 */
@interface ALListener : NSObject <OALSuspendManager>
{
	__unsafe_unretained ALContext* context; // Weak reference
	bool muted;
	float gain;
	
	/** Handles suspending and interrupting for this object. */
	OALSuspendHandler* suspendHandler;
}


#pragma mark Properties

/** The context this listener belongs to. */
@property(nonatomic,readonly) ALContext* context;

/** Causes this listener to stop hearing sound.
 * It's called "muted" rather than "deaf" to give a consistent name with other mute functions.
 */
@property(readwrite,assign) bool muted;

/** Gain (volume), affecting every sound this listener hears (0.0 = no sound, 1.0 = max volume).
 * Only valid if this listener's context is the current context.
 */
@property(readwrite,assign) float gain;

/** Orientation (up: x, y, z, at: x, y, z).
 * Only valid if this listener's context is the current context.
 */
@property(readwrite,assign) ALOrientation orientation;

/** Position (x, y, z).
 * Only valid if this listener's context is the current context.
 */
@property(readwrite,assign) ALPoint position;

/** Velocity (x, y, z).
* Only valid if this listener's context is the current context.
*/
@property(readwrite,assign) ALVector velocity;


#pragma mark Object Management

/** (INTERNAL USE) Create a listener for the specified context.
 *
 * @param context the context to create this listener on.
 * @return A new listener.
 */
+ (id) listenerForContext:(ALContext*) context;

/** (INTERNAL USE) Initialize a listener for the specified context.
 *
 * @param context the context to create this listener on.
 * @return The initialized listener.
 */
- (id) initWithContext:(ALContext*) context;

@end
