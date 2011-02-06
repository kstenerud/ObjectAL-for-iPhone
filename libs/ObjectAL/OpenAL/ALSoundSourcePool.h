//
//  SoundSourcePool.h
//  ObjectAL
//
//  Created by Karl Stenerud on 17/12/09.
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALSoundSource.h"


#pragma mark ALSoundSourcePool

/**
 * A pool of sound sources, which can be fetched based on availability.
 */
@interface ALSoundSourcePool : NSObject
{
	/** All sources managed by this pool (id<ALSoundSource>). */
	NSMutableArray* sources;
}


#pragma mark Properties

/** All sources managed by this pool (id<ALSoundSource>). */
@property(readonly) NSArray* sources;


#pragma mark Object Management

/** Make a new pool.
 * @return A new pool.
 */
+ (id) pool;

/** Close any OS resources in use by this object.
 * Any operations called on this object after closing will likely fail.
 */
- (void) close;


#pragma mark Source Management

/** Add a source to this pool.
 *
 * @param source The source to add.
 */
- (void) addSource:(id<ALSoundSource>) source;

/** Remove a source from this pool
 *
 * @param source The source to remove.
 */
- (void) removeSource:(id<ALSoundSource>) source;

/** Acquire a free or freeable source from this pool.
 * It first attempts to find a completely free source.
 * Failing this, it will attempt to interrupt a source and return that (if attemptToInterrupt
 * is TRUE).
 *
 * @param attemptToInterrupt If TRUE, attempt to interrupt sources to free them for use.
 * @return The freed sound source, or nil if no sources are freeable.
 */
- (id<ALSoundSource>) getFreeSource:(bool) attemptToInterrupt;

@end
