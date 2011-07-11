//
//  ALSource.h
//  ObjectAL
//
//  Created by Karl Stenerud on 15/12/09.
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

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import "ALSoundSource.h"
#import "ALBuffer.h"
#import "OALAction.h"
#import "OALSuspendHandler.h"

@class ALContext;


#pragma mark ALSource

/**
 * A source represents an object that emits sound which can be heard by a listener.
 * This source can have position, velocity, and direction.
 */
@interface ALSource : NSObject <ALSoundSource, OALSuspendManager>
{
	unsigned int sourceId;
	bool interruptible;
	float gain;
	bool muted;

	/** Shadow value which keeps the correct state value
	 * for AL_PLAYING and AL_PAUSED.
	 * We need this due to a buggy OpenAL implementation.
	 */
	int shadowState;
	
	/** Used to abort a pending playback resume if the user calls
	 * stop or pause.
	 */
	bool abortPlaybackResume;

	ALBuffer* buffer;
	ALContext* context;

	/** Current action operating on the gain control. */
	OALAction* gainAction;

	/** Current action operating on the pan control. */
	OALAction* panAction;

	/** Current action operating on the pitch control. */
	OALAction* pitchAction;
	
	/** Handles suspending and interrupting for this object. */
	OALSuspendHandler* suspendHandler;
}


#pragma mark Properties

/** The sound buffer this source is attached to (set to nil to detach the currently attached
 * buffer).
 */
@property(readwrite,retain) ALBuffer* buffer;

/** How many buffers this source has queued. */
@property(readonly) int buffersQueued;

/** How many of these buffers have been processed during playback. */
@property(readonly) int buffersProcessed;

/** The context this source was opened on. */
@property(readonly) ALContext* context;

/** The offset into the current buffer (in bytes). */
@property(readwrite,assign) float offsetInBytes;

/** The offset into the current buffer (in samples). */
@property(readwrite,assign) float offsetInSamples;

/** The offset into the current buffer (in seconds). */
@property(readwrite,assign) float offsetInSeconds;

/** OpenAL's ID for this source. */
@property(readonly) unsigned int sourceId;

/** The state of this source. */
@property(readwrite,assign) int state;


#pragma mark Object Management

/** Create a new source.
 *
 * @return A new source.
 */
+ (id) source;

/** Create a new source on the specified context.
 *
 * @param context the context to create the source on.
 * @return A new source.
 */
+ (id) sourceOnContext:(ALContext*) context;

/** Initialize a new source on the specified context.
 *
 * @param context the context to create the source on.
 * @return A new source.
 */
- (id) initOnContext:(ALContext*) context;


#pragma mark Playback

/** Play the currently attached buffer.
 *
 * @return the source playing the sound, or nil if the sound could not be played.
 */
- (id<ALSoundSource>) play;


#pragma mark Queued Playback

/** Add a buffer to the buffer queue.
 *
 * @param buffer the buffer to add to the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffer:(ALBuffer*) buffer;

/** Add a buffer to the buffer queue, repeating it multiple times.
 *
 * @param buffer the buffer to add to the queue.
 * @param times the number of times to repeat the buffer in the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffer:(ALBuffer*) bufferIn repeats:(NSUInteger) repeats;

/** Add buffers to the buffer queue.
 *
 * @param buffers the buffers to add to the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffers:(NSArray*) buffers;

/** Add buffers to the buffer queue, repeating it multiple times.
 * The buffers will be played in order, repeating the specified number of times.
 *
 * @param buffers the buffers to add to the queue.
 * @param times the number of times to repeat the buffer in the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffers:(NSArray*) buffers repeats:(NSUInteger) repeats;

/** Remove a buffer from the buffer queue.
 *
 * @param buffer the buffer to remove from the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) unqueueBuffer:(ALBuffer*) buffer;

/** Remove buffers from the buffer queue
 *
 * @param buffers the buffers to remove from the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) unqueueBuffers:(NSArray*) buffers;

@end
