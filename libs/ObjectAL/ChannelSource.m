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

@synthesize coneInnerAngle;

- (void) setConeInnerAngle:(float) value
{
	coneInnerAngle = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.coneInnerAngle = value;
	}
}

@synthesize coneOuterAngle;

- (void) setConeOuterAngle:(float) value
{
	coneOuterAngle = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.coneOuterAngle = value;
	}
}

@synthesize coneOuterGain;

- (void) setConeOuterGain:(float) value
{
	coneOuterGain = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.coneOuterGain = value;
	}
}

@synthesize context;

- (ALVector) direction
{
	return direction;
}

- (void) setDirection:(ALVector) value
{
	direction = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.direction = value;
	}
}

@synthesize gain;

- (void) setGain:(float) value
{
	gain = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.gain = value;
	}
}

@synthesize interruptible;

- (void) setInterruptible:(bool) value
{
	interruptible = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.interruptible = value;
	}
}

@synthesize looping;

- (void) setLooping:(bool) value
{
	looping = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.looping = value;
	}
}

@synthesize maxDistance;

- (void) setMaxDistance:(float) value
{
	maxDistance = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.maxDistance = value;
	}
}

@synthesize maxGain;

- (void) setMaxGain:(float) value
{
	maxGain = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.maxGain = value;
	}
}

@synthesize minGain;

- (void) setMinGain:(float) value
{
	minGain = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.minGain = value;
	}
}

@synthesize muted;

- (void) setMuted:(bool) value
{
	muted = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.muted = value;
	}
}

- (bool) paused
{
	for(id<SoundSource> source in sourcePool.sources)
	{
		if(source.paused)
		{
			return YES;
		}
	}
	return NO;
}

- (void) setPaused:(bool) value
{
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.paused = value;
	}
}

@synthesize pitch;

- (void) setPitch:(float) value
{
	pitch = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.pitch = value;
	}
}

- (bool) playing
{
	for(id<SoundSource> source in sourcePool.sources)
	{
		if(source.playing)
		{
			return YES;
		}
	}
	return NO;
}

- (ALPoint) position
{
	return position;
}

- (void) setPosition:(ALPoint) value
{
	position = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.position = value;
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

@synthesize referenceDistance;

- (void) setReferenceDistance:(float) value
{
	referenceDistance = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.referenceDistance = value;
	}
}

@synthesize rolloffFactor;

- (void) setRolloffFactor:(float) value
{
	rolloffFactor = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.rolloffFactor = value;
	}
}

@synthesize sourceRelative;

- (void) setSourceRelative:(int) value
{
	sourceRelative = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.sourceRelative = value;
	}
}

@synthesize sourceType;

- (void) setSourceType:(int) value
{
	sourceType = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.sourceType = value;
	}
}

@synthesize sourcePool;

- (ALVector) velocity
{
	return velocity;
}

- (void) setVelocity:(ALVector) value
{
	velocity = value;
	for(id<SoundSource> source in sourcePool.sources)
	{
		source.velocity = value;
	}
}


#pragma mark Playback

- (id<SoundSource>) play
{
	// Do nothing.
	NSLog(@"Warning: ChannelSource: \"play\" does nothing in ChannelSource.  Use \"play:(ALBuffer*) buffer loop:(bool) loop\" instead.");
	return nil;
}

- (id<SoundSource>) play:(ALBuffer*) buffer
{
	return [self play:buffer loop:NO];
}

- (id<SoundSource>) play:(ALBuffer*) buffer loop:(bool) loop
{
	if(muted)
	{
		return nil;
	}
	
	// Try to find a free source for playback.
	// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
	id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
	if(nil != soundSource)
	{
		return [soundSource play:buffer loop:loop];
	}
	return nil;
}

- (id<SoundSource>) play:(ALBuffer*) buffer gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loop
{
	if(muted)
	{
		return nil;
	}

	// Try to find a free source for playback.
	// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
	id<SoundSource> soundSource = [sourcePool getFreeSource:interruptible];
	if(nil != soundSource)
	{
		return [soundSource play:buffer gain:gainIn pitch:pitchIn pan:panIn loop:loop];
	}
	return nil;
}

- (void) stop
{
	for(id<SoundSource> source in sourcePool.sources)
	{
		[source stop];
	}
}

- (void) clear
{
	for(id<SoundSource> source in sourcePool.sources)
	{
		[source clear];
	}
}

@end
