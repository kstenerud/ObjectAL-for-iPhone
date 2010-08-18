//
//  ChannelSource.m
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

#import "ChannelSource.h"
#import "ObjectALMacros.h"
#import "ObjectAL.h"


@implementation ChannelSource

#pragma mark Object Management

+ (id) channelWithSources:(int) numSources
{
	return [[[self alloc] initWithSources:numSources] autorelease];
}

- (id) initWithSources:(int) numSources
{
	if(nil != (self = [super init]))
	{
		context = [[ObjectAL sharedInstance].currentContext retain];

		// Create some OpenAL sound sources
		sourcePool = [[SoundSourcePool pool] retain];
		for(int i = 0; i < numSources; i++)
		{
			[sourcePool addSource:[ALSource source]];
		}
		
		// Set this channel's properties from the OpenAL sound source defaults
		id<SoundSource> firstSource = [sourcePool.sources objectAtIndex:0];
		pitch = firstSource.pitch;
		gain = firstSource.gain;
		maxDistance = firstSource.maxDistance;
		rolloffFactor = firstSource.rolloffFactor;
		referenceDistance = firstSource.referenceDistance;
		minGain = firstSource.minGain;
		maxGain = firstSource.maxGain;
		coneOuterGain = firstSource.coneOuterGain;
		coneInnerAngle = firstSource.coneInnerAngle;
		coneOuterAngle = firstSource.coneOuterAngle;
		position = firstSource.position;
		velocity = firstSource.velocity;
		direction = firstSource.direction;
		sourceRelative = firstSource.sourceRelative;
		sourceType = firstSource.sourceType;
		looping = firstSource.looping;
	}
	return self;
}

- (void) dealloc
{
	[sourcePool release];
	[context release];
	[super dealloc];
}


#pragma mark Properties

- (float) coneInnerAngle
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return coneInnerAngle;
	}
}

- (void) setConeInnerAngle:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		coneInnerAngle = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.coneInnerAngle = value;
		}
	}
}

- (float) coneOuterAngle
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return coneOuterAngle;
	}
}

- (void) setConeOuterAngle:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		coneOuterAngle = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.coneOuterAngle = value;
		}
	}
}

- (float) coneOuterGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return coneOuterGain;
	}
}

- (void) setConeOuterGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		coneOuterGain = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.coneOuterGain = value;
		}
	}
}

@synthesize context;

- (ALVector) direction
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return direction;
	}
}

- (void) setDirection:(ALVector) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		direction = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.direction = value;
		}
	}
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
		gain = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.gain = value;
		}
	}
}

- (bool) interruptible
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return interruptible;
	}
}

- (void) setInterruptible:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		interruptible = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.interruptible = value;
		}
	}
}

- (bool) looping
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return looping;
	}
}

- (void) setLooping:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		looping = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.looping = value;
		}
	}
}

- (float) maxDistance
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return maxDistance;
	}
}

- (void) setMaxDistance:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		maxDistance = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.maxDistance = value;
		}
	}
}

- (float) maxGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return maxGain;
	}
}

- (void) setMaxGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		maxGain = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.maxGain = value;
		}
	}
}

- (float) minGain
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return minGain;
	}
}

- (void) setMinGain:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		minGain = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.minGain = value;
		}
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
		muted = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.muted = value;
		}
	}
}

- (bool) paused
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return paused;
	}
}

- (void) setPaused:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		paused = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.paused = value;
		}
	}
}

- (float) pitch
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return pitch;
	}
}

- (void) setPitch:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		pitch = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.pitch = value;
		}
	}
}

- (bool) playing
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			if(source.playing)
			{
				return YES;
			}
		}
	}
	return NO;
}

- (ALPoint) position
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return position;
	}
}

- (void) setPosition:(ALPoint) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		position = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.position = value;
		}
	}
}

- (float) pan
{
	return position.x;
}

- (void) setPan:(float) value
{
	[self setPosition:alpoint(value, 0, 0)];
}

- (float) referenceDistance
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return referenceDistance;
	}
}

- (void) setReferenceDistance:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		referenceDistance = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.referenceDistance = value;
		}
	}
}

- (float) rolloffFactor
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return rolloffFactor;
	}
}

- (void) setRolloffFactor:(float) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		rolloffFactor = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.rolloffFactor = value;
		}
	}
}

- (int) sourceRelative
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return sourceRelative;
	}
}

- (void) setSourceRelative:(int) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		sourceRelative = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.sourceRelative = value;
		}
	}
}

- (int) sourceType
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return sourceType;
	}
}

- (void) setSourceType:(int) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		sourceType = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.sourceType = value;
		}
	}
}

@synthesize sourcePool;

- (ALVector) velocity
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return velocity;
	}
}

- (void) setVelocity:(ALVector) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		velocity = value;
		for(id<SoundSource> source in sourcePool.sources)
		{
			source.velocity = value;
		}
	}
}


#pragma mark Playback

- (id<SoundSource>) play
{
	// Do nothing.
	LOG_WARNING(@"\"play\" does nothing in ChannelSource.  Use \"play:(ALBuffer*) buffer loop:(bool) loop\" instead.");
	return nil;
}

- (id<SoundSource>) play:(ALBuffer*) buffer
{
	return [self play:buffer loop:NO];
}

- (id<SoundSource>) play:(ALBuffer*) buffer loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer loop:loop];
	}
}

- (id<SoundSource>) play:(ALBuffer*) buffer gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer gain:gainIn pitch:pitchIn pan:panIn loop:loop];
	}
}

- (void) stop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source stop];
		}
	}
}

- (void) fadeTo:(float) value duration:(float) duration target:(id) target selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		[self stopFade];
		fadeCompleteTarget = target;
		fadeCompleteSelector = selector;

		currentFadeCallbackCount = 0;
		expectedFadeCallbackCount = [sourcePool.sources count];
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source fadeTo:value duration:duration target:self selector:@selector(onFadeComplete:)];
		}
	}
}

- (void) onFadeComplete:(id<SoundSource>) source
{
	// Must always be synchronized
	@synchronized(self)
	{
		currentFadeCallbackCount++;
		if(currentFadeCallbackCount == expectedFadeCallbackCount)
		{
			[fadeCompleteTarget performSelector:fadeCompleteSelector withObject:self];
		}
	}
}

- (void) stopFade
{
	// Must always be synchronized
	@synchronized(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source stopFade];
		}
	}
}


- (void) clear
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source clear];
		}
	}
}

@end
