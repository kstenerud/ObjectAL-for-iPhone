//
//  ALListener.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-07.
//
// Copyright 2009 Karl Stenerud
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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import "ALTypes.h"

@class ALContext;


#pragma mark ALListener

/**
 * The listener represents the user who is listening to sounds in 3D space.
 * This object controls his position, orientation, and velocity, as well as providing a master
 * gain. <br>
 * A context contains one and only one listener.
 */
@interface ALListener : NSObject
{
	ALContext* context; // Weak reference
	bool muted;
	float gain;
}


#pragma mark Properties

/** The context this listener belongs to. */
@property(readonly) ALContext* context;

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
