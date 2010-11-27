//
//  ALSource.m
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

#import "ALSource.h"
#import "mach_timing.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "OpenALManager.h"
#import "OALAudioActions.h"
#import "OALUtilityActions.h"


@implementation ALSource

#pragma mark Object Management

+ (id) source
{
	return [[[self alloc] init] autorelease];
}

+ (id) sourceOnContext:(ALContext*) context
{
	return [[[self alloc] initOnContext:context] autorelease];
}

- (id) init
{
	return [self initOnContext:[OpenALManager sharedInstance].currentContext];
}

- (id) initOnContext:(ALContext*) contextIn
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init on context %@", self, contextIn);
		context = [contextIn retain];
		@synchronized([OpenALManager sharedInstance])
		{
			ALContext* oldContext = [OpenALManager sharedInstance].currentContext;
			[OpenALManager sharedInstance].currentContext = context;
			sourceId = [ALWrapper genSource];
			[OpenALManager sharedInstance].currentContext = oldContext;
		}
		
		[context notifySourceInitializing:self];
		gain = [ALWrapper getSourcef:sourceId parameter:AL_GAIN];
		suspendLock = [[SuspendLock lockWithTarget:self
									  lockSelector:@selector(onSuspend)
									unlockSelector:@selector(onUnsuspend)] retain];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	[context notifySourceDeallocating:self];
	
	[gainAction stopAction];
	[gainAction release];
	[panAction stopAction];
	[panAction release];
	[pitchAction stopAction];
	[pitchAction release];
	[suspendLock release];

	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper sourceStop:sourceId];
		[ALWrapper sourcei:sourceId parameter:AL_BUFFER value:AL_NONE];
	}

	// In IOS 3.x, OpenAL doesn't stop playing right away.
	// Release after a delay to give it some time to stop.
	[buffer performSelector:@selector(release) withObject:nil afterDelay:0.1];
	
	@synchronized([OpenALManager sharedInstance])
	{
		ALContext* oldContext = [OpenALManager sharedInstance].currentContext;
		[OpenALManager sharedInstance].currentContext = context;
		[ALWrapper deleteSource:sourceId];
		[OpenALManager sharedInstance].currentContext = oldContext;
	}
	[context release];

	[super dealloc];
}


#pragma mark Properties

- (ALBuffer*) buffer
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return buffer;
	}
}

- (void) setBuffer:(ALBuffer *) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
			
		[self stop];

		// In IOS 3.x, OpenAL doesn't stop playing right away.
		// Release after a delay to give it some time to stop.
		[buffer performSelector:@selector(release) withObject:nil afterDelay:0.1];

		buffer = [value retain];
		[ALWrapper sourcei:sourceId parameter:AL_BUFFER value:buffer.bufferId];
	}
}

- (int) buffersQueued
{
	return [ALWrapper getSourcei:sourceId parameter:AL_BUFFERS_QUEUED];
}

- (int) buffersProcessed
{
	return [ALWrapper getSourcei:sourceId parameter:AL_BUFFERS_PROCESSED];
}

- (float) coneInnerAngle
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_INNER_ANGLE];
	}
}

- (void) setConeInnerAngle:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_CONE_INNER_ANGLE value:value];
	}
}

- (float) coneOuterAngle
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_OUTER_ANGLE];
	}
}

- (void) setConeOuterAngle:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_CONE_OUTER_ANGLE value:value];
	}
}

- (float) coneOuterGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_OUTER_GAIN];
	}
}

- (void) setConeOuterGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_CONE_OUTER_GAIN value:value];
	}
}

@synthesize context;

- (ALVector) direction
{
	ALVector result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_DIRECTION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setDirection:(ALVector) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper source3f:sourceId parameter:AL_DIRECTION v1:value.x v2:value.y v3:value.z];
	}
}

- (float) volume
{
	return self.gain;
}

- (void) setVolume:(float) value
{
	self.gain = value;
}

- (float) gain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return gain;
	}
}

- (void) setGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		gain = value;
		if(muted)
		{
			value = 0;
		}
		[ALWrapper sourcef:sourceId parameter:AL_GAIN value:value];
	}
}

@synthesize interruptible;

- (bool) looping
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_LOOPING];
	}
}

- (void) setLooping:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcei:sourceId parameter:AL_LOOPING value:value];
	}
}

- (float) maxDistance
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MAX_DISTANCE];
	}
}

- (void) setMaxDistance:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_MAX_DISTANCE value:value];
	}
}

- (float) maxGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MAX_GAIN];
	}
}

- (void) setMaxGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_MAX_GAIN value:value];
	}
}

- (float) minGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MIN_GAIN];
	}
}

- (void) setMinGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_MIN_GAIN value:value];
	}
}

- (bool) muted
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return muted;
	}
}

- (void) setMuted:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		muted = value;
		if(muted)
		{
			[self stopActions];
		}
		float resultingGain = muted ? 0 : gain;
		[ALWrapper sourcef:sourceId parameter:AL_GAIN value:resultingGain];
	}
}

- (float) offsetInBytes
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_BYTE_OFFSET];
	}
}

- (void) setOffsetInBytes:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_BYTE_OFFSET value:value];
	}
}

- (float) offsetInSamples
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_SAMPLE_OFFSET];
	}
}

- (void) setOffsetInSamples:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_SAMPLE_OFFSET value:value];
	}
}

- (float) offsetInSeconds
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_SEC_OFFSET];
	}
}

- (void) setOffsetInSeconds:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_SEC_OFFSET value:value];
	}
}

- (bool) paused
{
	if(suspendLock.locked)
	{
		return AL_PAUSED == stateOnSuspend;
	}

	return AL_PAUSED == stateOnSuspend || AL_PAUSED == self.state;
}

- (void) setPaused:(bool) shouldPause
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		if(shouldPause)
		{
			if(AL_PLAYING == self.state && AL_PAUSED != stateOnSuspend)
			{
				[ALWrapper sourcePause:sourceId];
			}
		}
		else
		{
			if(AL_PAUSED == self.state || AL_PAUSED == stateOnSuspend)
			{
				[ALWrapper sourcePlay:sourceId];
			}
		}
		stateOnSuspend = 0;
	}
}

- (float) pitch
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_PITCH];
	}
}

- (void) setPitch:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_PITCH value:value];
	}
}

- (bool) playing
{
	if(suspendLock.locked)
	{
		return AL_PLAYING == stateOnSuspend || AL_PAUSED == stateOnSuspend;
	}
	return AL_PLAYING == self.state || AL_PAUSED == self.state;
}

- (ALPoint) position
{
	ALPoint result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_POSITION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setPosition:(ALPoint) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper source3f:sourceId parameter:AL_POSITION v1:value.x v2:value.y v3:value.z];
	}
}

- (float) pan
{
	return self.position.x;
}

- (void) setPan:(float) value
{
	if(suspendLock.locked)
	{
		OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
		return;
	}
	
	self.position = alpoint(value, 0, 0);
}

- (float) referenceDistance
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_REFERENCE_DISTANCE];
	}
}

- (void) setReferenceDistance:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_REFERENCE_DISTANCE value:value];
	}
}

- (float) rolloffFactor
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_ROLLOFF_FACTOR];
	}
}

- (void) setRolloffFactor:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcef:sourceId parameter:AL_ROLLOFF_FACTOR value:value];
	}
}

@synthesize sourceId;

- (int) sourceRelative
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_RELATIVE];
	}
}

- (void) setSourceRelative:(int) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_RELATIVE value:value];
	}
}

- (int) sourceType
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_TYPE];
	}
}

- (void) setSourceType:(int) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_TYPE value:value];
	}
}

- (int) state
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_STATE];
	}
}

- (void) setState:(int) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_STATE value:value];
	}
}

- (ALVector) velocity
{
	ALVector result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_VELOCITY v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setVelocity:(ALVector) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper source3f:sourceId parameter:AL_VELOCITY v1:value.x v2:value.y v3:value.z];
	}
}

/** Called by SuspendLock to suspend this object.
 */
- (void) onSuspend
{
	stateOnSuspend = self.state;
	byteOffsetOnSuspend = self.offsetInBytes;

	if(AL_PLAYING == stateOnSuspend)
	{
		[ALWrapper sourcePause:sourceId];
	}
}

/** Called by SuspendLock to unsuspend this object.
 */
- (void) onUnsuspend
{
	if(AL_PAUSED == stateOnSuspend || AL_PLAYING == stateOnSuspend)
	{
		[ALWrapper sourcePlay:sourceId];
		self.offsetInBytes = byteOffsetOnSuspend;
		NSLog(@"### Start playing. state = %d", self.state);
		
		if(AL_PAUSED == stateOnSuspend)
		{
			[ALWrapper sourcePause:sourceId];
			NSLog(@"### Pause. state = %d", self.state);
		}
	}
}

- (bool) suspended
{
	// No need to synchronize since SuspendLock does that already.
	return suspendLock.suspendLock;
}

- (void) setSuspended:(bool) value
{
	// No need to synchronize since SuspendLock does that already.
	suspendLock.suspendLock = value;
}

- (bool) interrupted
{
	// No need to synchronize since SuspendLock does that already.
	return suspendLock.interruptLock;
}

- (void) setInterrupted:(bool) value
{
	// No need to synchronize since SuspendLock does that already.
	suspendLock.interruptLock = value;
}


#pragma mark Playback

- (void) preload:(ALBuffer*) bufferIn
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[self stopActions];

		if(self.playing || self.paused)
		{
			[self stop];
		}
	
		self.buffer = bufferIn;
	}
}

- (id<ALSoundSource>) play
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return nil;
		}
		
		[self stopActions];

		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		if(self.paused)
		{
			[self stop];
		}
		
		stateOnSuspend = 0;
		[ALWrapper sourcePlay:sourceId];
	}
	return self;
}

- (id<ALSoundSource>) play:(ALBuffer*) bufferIn
{
	return [self play:bufferIn loop:NO];
}

- (id<ALSoundSource>) play:(ALBuffer*) bufferIn loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return nil;
		}
		
		[self stopActions];

		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		self.buffer = bufferIn;
		self.looping = loop;
		
		stateOnSuspend = 0;
		[ALWrapper sourcePlay:sourceId];
	}
	return self;
}

- (id<ALSoundSource>) play:(ALBuffer*) bufferIn gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loopIn
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return nil;
		}
		
		[self stopActions];

		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		self.buffer = bufferIn;
		
		// Set gain, pitch, and pan
		self.gain = gainIn;
		self.pitch = pitchIn;
		self.pan = panIn;
		self.looping = loopIn;
		
		stateOnSuspend = 0;
		[ALWrapper sourcePlay:sourceId];
	}		
	return self;
}

- (void) stop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[self stopActions];
		stateOnSuspend = 0;
		[ALWrapper sourceStop:sourceId];
	}
}

- (void) fadeTo:(float) value
	   duration:(float) duration
		 target:(id) target
	   selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[self stopFade];
		gainAction = [[OALSequentialActions actions:
					   [OALGainAction actionWithDuration:duration endValue:value],
					   [OALCallAction actionWithCallTarget:target selector:selector withObject:self],
					   nil] retain];
		[gainAction runWithTarget:self];
	}
}

- (void) stopFade
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[gainAction stopAction];
		[gainAction release];
		gainAction = nil;
	}
}

- (void) panTo:(float) value
	   duration:(float) duration
		 target:(id) target
	   selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[self stopPan];
		gainAction = [[OALSequentialActions actions:
					   [OALPanAction actionWithDuration:duration endValue:value],
					   [OALCallAction actionWithCallTarget:target selector:selector withObject:self],
					   nil] retain];
		[gainAction runWithTarget:self];
	}
}

- (void) stopPan
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[gainAction stopAction];
		[gainAction release];
		gainAction = nil;
	}
}

- (void) pitchTo:(float) value
	  duration:(float) duration
		target:(id) target
	  selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[self stopPitch];
		gainAction = [[OALSequentialActions actions:
					   [OALPitchAction actionWithDuration:duration endValue:value],
					   [OALCallAction actionWithCallTarget:target selector:selector withObject:self],
					   nil] retain];
		[gainAction runWithTarget:self];
	}
}

- (void) stopPitch
{
	// Must always be synchronized
	@synchronized(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[gainAction stopAction];
		[gainAction release];
		gainAction = nil;
	}
}

- (void) stopActions
{
	[self stopFade];
	[self stopPan];
	[self stopPitch];
}

- (void) clear
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[self setSuspended:NO];
		[self stop];
		self.buffer = nil;
	}
}


#pragma mark Queued Playback

- (bool) queueBuffer:(ALBuffer*) bufferIn
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return NO;
		}
		
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		ALuint bufferId = bufferIn.bufferId;
		return [ALWrapper sourceQueueBuffers:sourceId numBuffers:1 bufferIds:&bufferId];
	}
}

- (bool) queueBuffers:(NSArray*) buffers
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return NO;
		}
		
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		int numBuffers = [buffers count];
		ALuint* bufferIds = (ALuint*)malloc(sizeof(ALuint) * numBuffers);
		int i = 0;
		for(ALBuffer* buf in buffers)
		{
			bufferIds[i] = buf.bufferId;
		}
		bool result = [ALWrapper sourceQueueBuffers:sourceId numBuffers:numBuffers bufferIds:bufferIds];
		free(bufferIds);
		return result;
	}
}

- (bool) unqueueBuffer:(ALBuffer*) bufferIn
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return NO;
		}
		
		ALuint bufferId = bufferIn.bufferId;
		return [ALWrapper sourceUnqueueBuffers:sourceId numBuffers:1 bufferIds:&bufferId];
	}
}

- (bool) unqueueBuffers:(NSArray*) buffers
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return NO;
		}
		
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		int numBuffers = [buffers count];
		ALuint* bufferIds = malloc(sizeof(ALuint) * numBuffers);
		int i = 0;
		for(ALBuffer* buf in buffers)
		{
			bufferIds[i] = buf.bufferId;
		}
		bool result = [ALWrapper sourceUnqueueBuffers:sourceId numBuffers:numBuffers bufferIds:bufferIds];
		free(bufferIds);
		return result;
	}
}

#pragma mark Internal Use

- (bool) requestUnreserve:(bool) interrupt
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(self.playing)
		{
			if(!self.interruptible || !interrupt)
			{
				return NO;
			}
			[self stop];
		}
		self.buffer = nil;
	}
	return YES;
}


@end
