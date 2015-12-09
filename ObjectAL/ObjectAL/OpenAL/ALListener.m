//
//  ALListener.m
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

#import "ALListener.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "ALContext.h"


/** \cond */
@interface ALListener ()

@property(nonatomic,readwrite,assign) ALContext* context;

@end
/** \endcond */


@implementation ALListener

#pragma mark Object Management

+ (id) listenerForContext:(ALContext*) context
{
	return [[self alloc] initWithContext:context];
}

- (id) initWithContext:(ALContext*) contextIn
{
	if(nil != (self = [super init]))
	{
        if(contextIn == nil)
        {
            OAL_LOG_ERROR(@"%@: Could not init listener: Context is nil", self);
            return nil;
        }
		suspendHandler = [[OALSuspendHandler alloc] initWithTarget:nil selector:nil];

		self.context = contextIn;
		gain = 1.0f;
	}
	return self;
}

#pragma mark Properties

@synthesize context;

- (bool) muted
{
    return muted;
}

- (void) setMuted:(bool) value
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		muted = value;
		// Force a re-evaluation of gain.
		[self setGain:gain];
	}
}

- (float) gain
{
    return gain;
}

- (void) setGain:(float) value
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		gain = value;
		if(muted)
		{
			value = 0;
		}
		[ALWrapper listenerf:AL_GAIN value:value];
	}
}

- (ALOrientation) orientation
{
	ALOrientation result;
	@synchronized(self)
	{
		[ALWrapper getListenerfv:AL_ORIENTATION values:(float*)&result];
	}
	return result;
}

- (void) setOrientation:(ALOrientation) value
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper listenerfv:AL_ORIENTATION values:(float*)&value];
	}
}

- (ALPoint) position
{
	ALPoint result;
	@synchronized(self)
	{
		[ALWrapper getListener3f:AL_POSITION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setPosition:(ALPoint) value
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper listener3f:AL_POSITION v1:value.x v2:value.y v3:value.z];
	}
}

- (ALVector) velocity
{
	ALVector result;
	@synchronized(self)
	{
		[ALWrapper getListener3f:AL_VELOCITY v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setVelocity:(ALVector) value
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper listener3f:AL_VELOCITY v1:value.x v2:value.y v3:value.z];
	}
}

- (bool) reverbOn
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListenerb:ALC_ASA_REVERB_ON];
	}
}

- (void) setReverbOn:(bool) reverbOn
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListenerb:ALC_ASA_REVERB_ON value:reverbOn];
	}
}

- (float) globalReverbLevel
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListenerf:ALC_ASA_REVERB_GLOBAL_LEVEL];
	}
}

- (void) setGlobalReverbLevel:(float) globalReverbLevel
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListenerf:ALC_ASA_REVERB_GLOBAL_LEVEL value:globalReverbLevel];
	}
}

- (int) reverbRoomType
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListeneri:ALC_ASA_REVERB_ROOM_TYPE];
	}
}

- (void) setReverbRoomType:(int) reverbRoomType
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListeneri:ALC_ASA_REVERB_ROOM_TYPE value:reverbRoomType];
	}
}

- (float) reverbEQGain
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListenerf:ALC_ASA_REVERB_EQ_GAIN];
	}
}

- (void) setReverbEQGain:(float) reverbEQGain
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListenerf:ALC_ASA_REVERB_EQ_GAIN value:reverbEQGain];
	}
}

- (float) reverbEQBandwidth
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListenerf:ALC_ASA_REVERB_EQ_BANDWITH];
	}
}

- (void) setReverbEQBandwidth:(float) reverbEQBandwidth
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListenerf:ALC_ASA_REVERB_EQ_BANDWITH value:reverbEQBandwidth];
	}
}

- (float) reverbEQFrequency
{
	@synchronized(self)
	{
        return [ALWrapper asaGetListenerf:ALC_ASA_REVERB_EQ_FREQ];
	}
}

- (void) setReverbEQFrequency:(float) reverbEQFrequency
{
	@synchronized(self)
	{
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper asaListenerf:ALC_ASA_REVERB_EQ_FREQ value:reverbEQFrequency];
	}
}


#pragma mark Suspend Handler

- (void) addSuspendListener:(id<OALSuspendListener>) listener
{
	[suspendHandler addSuspendListener:listener];
}

- (void) removeSuspendListener:(id<OALSuspendListener>) listener
{
	[suspendHandler removeSuspendListener:listener];
}

- (bool) manuallySuspended
{
	return suspendHandler.manuallySuspended;
}

- (void) setManuallySuspended:(bool) value
{
	suspendHandler.manuallySuspended = value;
}

- (bool) interrupted
{
	return suspendHandler.interrupted;
}

- (void) setInterrupted:(bool) value
{
	suspendHandler.interrupted = value;
}

- (bool) suspended
{
	return suspendHandler.suspended;
}

@end
