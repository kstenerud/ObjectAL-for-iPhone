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
	SYNCHRONIZED_OP(self)
	{
		return coneInnerAngle;
	}
}

- (void) setConeInnerAngle:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return coneOuterAngle;
	}
}

- (void) setConeOuterAngle:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return coneOuterGain;
	}
}

- (void) setConeOuterGain:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return direction;
	}
}

- (void) setDirection:(ALVector) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
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
	SYNCHRONIZED_OP(self)
	{
		return gain;
	}
}

- (void) setGain:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return interruptible;
	}
}

- (void) setInterruptible:(bool) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return looping;
	}
}

- (void) setLooping:(bool) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return maxDistance;
	}
}

- (void) setMaxDistance:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return maxGain;
	}
}

- (void) setMaxGain:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return minGain;
	}
}

- (void) setMinGain:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return muted;
	}
}

- (void) setMuted:(bool) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return paused;
	}
}

- (void) setPaused:(bool) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return pitch;
	}
}

- (void) setPitch:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return position;
	}
}

- (void) setPosition:(ALPoint) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
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
	SYNCHRONIZED_OP(self)
	{
		return referenceDistance;
	}
}

- (void) setReferenceDistance:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return rolloffFactor;
	}
}

- (void) setRolloffFactor:(float) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return sourceRelative;
	}
}

- (void) setSourceRelative:(int) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return sourceType;
	}
}

- (void) setSourceType:(int) value
{
	SYNCHRONIZED_OP(self)
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
	SYNCHRONIZED_OP(self)
	{
		return velocity;
	}
}

- (void) setVelocity:(ALVector) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
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
	SYNCHRONIZED_OP(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer loop:loop];
	}
}

- (id<SoundSource>) play:(ALBuffer*) buffer gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loop
{
	SYNCHRONIZED_OP(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer gain:gainIn pitch:pitchIn pan:panIn loop:loop];
	}
}

- (void) stop
{
	SYNCHRONIZED_OP(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source stop];
		}
	}
}

- (void) clear
{
	SYNCHRONIZED_OP(self)
	{
		for(id<SoundSource> source in sourcePool.sources)
		{
			[source clear];
		}
	}
}

@end
