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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import "SoundSource.h"
#import "ALBuffer.h"

@class ALContext;


#pragma mark ALSource

/**
 * A source represents an object that emits sound which can be heard by a listener.
 * This source can have position, velocity, and direction.
 */
@interface ALSource : NSObject <SoundSource>
{
	unsigned int sourceId;
	bool interruptible;
	float gain;
	bool muted;
	bool paused;
	ALBuffer* buffer;
	ALContext* context;

	/** Target to inform when the current fade operation completes. */
	id fadeCompleteTarget;
	
	/** Selector to call when the current fade operation completes. */
	SEL fadeCompleteSelector;
	
	/** The gain we started this fade from. */
	float fadeStartingGain;
	
	/** The gain we are fading to. */
	float fadeEndingGain;
	
	/** The duration of the fade operation. */
	float fadeDuration;
	
	/** A multiplier applied to the elapsed time to give a fade delta. */
	float fadeDeltaMultiplier;
	
	/** The time that this fade operation started. */
	uint64_t fadeStartTime;
	
	/** The timer corrdinating the fade operation. */
	NSTimer* fadeTimer;
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
- (id<SoundSource>) play;


#pragma mark Queued Playback

/** Add a buffer to the buffer queue.
 *
 * @param buffer the buffer to add to the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffer:(ALBuffer*) buffer;

/** Add buffers to the buffer queue.
 *
 * @param buffers the buffers to add to the queue.
 * @return TRUE if the operation was successful.
 */
- (bool) queueBuffers:(NSArray*) buffers;

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
