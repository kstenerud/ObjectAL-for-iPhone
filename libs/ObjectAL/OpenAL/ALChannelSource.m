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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALChannelSource.h"
#import "ObjectALMacros.h"
#import "OpenALManager.h"



#define SYNTHESIZE_DELEGATE_PROPERTY(NAME, CAPSNAME, TYPE) \
- (TYPE) NAME \
{ \
	OPTIONALLY_SYNCHRONIZED(self) \
	{ \
		return NAME; \
	} \
} \
 \
- (void) set##CAPSNAME:(TYPE) value \
{ \
	OPTIONALLY_SYNCHRONIZED(self) \
	{ \
		NAME = value; \
		for(id<ALSoundSource> source in sourcePool.sources) \
		{ \
			source.NAME = value; \
		} \
	} \
}



#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private methods for ALChannelSource.
 */
@interface ALChannelSource (Private)

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

/** (INTERNAL USE) Called by the action system when a fade completes.
 */
- (void) onFadeComplete:(id<ALSoundSource>) source;

/** (INTERNAL USE) Called by the action system when a pan completes.
 */
- (void) onPanComplete:(id<ALSoundSource>) source;

/** (INTERNAL USE) Called by the action system when a pitch change completes.
 */
- (void) onPitchComplete:(id<ALSoundSource>) source;

/** (INTERNAL USE) Set defaults from another channel.
 */
- (void) setDefaultsFromChannel:(ALChannelSource*) channel;

@end


@implementation ALChannelSource

#pragma mark Object Management

+ (id) channelWithSources:(unsigned int) reservedSources
{
	return [[[self alloc] initWithSources:reservedSources] autorelease];
}

- (id) initWithSources:(unsigned int) reservedSources
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init with %d sources", self, reservedSources);

		context = [[OpenALManager sharedInstance].currentContext retain];

		sourcePool = [[ALSoundSourcePool alloc] init];

        for(unsigned int i = 0; i < reservedSources; i++)
        {
            [self addSource:[ALSource source]];
        }            
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	
	[self closeOSResources];

	[sourcePool release];
	[context release];

	[super dealloc];
}

- (void) closeOSResources
{
	// Not directly holding any OS resources.
}

- (void) close
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != sourcePool)
		{
			[sourcePool close];
			[sourcePool release];
			sourcePool = nil;
			
			[self closeOSResources];
		}
	}
}

- (unsigned int) reservedSources
{
	return [sourcePool.sources count];
}

- (void) setReservedSources:(unsigned int) reservedSources
{
    while(self.reservedSources < reservedSources)
    {
        [self addSource:nil];
    }

    while(self.reservedSources > reservedSources)
    {
        [self removeSource:nil];
    }
}


#pragma mark Properties

@synthesize context;

@synthesize sourcePool;

- (float) volume
{
	return self.gain;
}

- (void) setVolume:(float) value
{
	self.gain = value;
}

- (float) pan
{
	return position.x;
}

- (void) setPan:(float) value
{
	[self setPosition:alpoint(value, 0, 0)];
}

- (int) sourceType
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return sourceType;
	}
}

- (bool) playing
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(id<ALSoundSource> source in sourcePool.sources)
		{
			if(source.playing)
			{
				return YES;
			}
		}
	}
	return NO;
}

SYNTHESIZE_DELEGATE_PROPERTY(coneInnerAngle, ConeInnerAngle, float);

SYNTHESIZE_DELEGATE_PROPERTY(coneOuterAngle, ConeOuterAngle, float);

SYNTHESIZE_DELEGATE_PROPERTY(coneOuterGain, ConeOuterGain, float);

SYNTHESIZE_DELEGATE_PROPERTY(direction, Direction, ALVector);

SYNTHESIZE_DELEGATE_PROPERTY(gain, Gain, float);

SYNTHESIZE_DELEGATE_PROPERTY(interruptible, Interruptible, bool);

SYNTHESIZE_DELEGATE_PROPERTY(looping, Looping, bool);

SYNTHESIZE_DELEGATE_PROPERTY(maxDistance, MaxDistance, float);

SYNTHESIZE_DELEGATE_PROPERTY(maxGain, MaxGain, float);

SYNTHESIZE_DELEGATE_PROPERTY(minGain, MinGain, float);

SYNTHESIZE_DELEGATE_PROPERTY(muted, Muted, bool);

SYNTHESIZE_DELEGATE_PROPERTY(paused, Paused, bool);

SYNTHESIZE_DELEGATE_PROPERTY(pitch, Pitch, float);

SYNTHESIZE_DELEGATE_PROPERTY(position, Position, ALPoint);

SYNTHESIZE_DELEGATE_PROPERTY(referenceDistance, ReferenceDistance, float);

SYNTHESIZE_DELEGATE_PROPERTY(rolloffFactor, RolloffFactor, float);

SYNTHESIZE_DELEGATE_PROPERTY(sourceRelative, SourceRelative, int);

SYNTHESIZE_DELEGATE_PROPERTY(velocity, Velocity, ALVector);



#pragma mark Playback

- (id<ALSoundSource>) play
{
	// Do nothing.
	OAL_LOG_WARNING(@"%@: \"play\" does nothing in ChannelSource.  Use \"play:(ALBuffer*) buffer loop:(bool) loop\" instead.", self);
	return nil;
}

- (id<ALSoundSource>) play:(ALBuffer*) buffer
{
	return [self play:buffer loop:NO];
}

- (id<ALSoundSource>) play:(ALBuffer*) buffer loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<ALSoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer loop:loop];
	}
}

- (id<ALSoundSource>) play:(ALBuffer*) buffer gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		// Try to find a free source for playback.
		// If this channel is not interruptible, it will not attempt to interrupt its contained sources.
		id<ALSoundSource> soundSource = [sourcePool getFreeSource:interruptible];
		return [soundSource play:buffer gain:gainIn pitch:pitchIn pan:panIn loop:loop];
	}
}

- (void) stop
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        [sourcePool.sources makeObjectsPerformSelector:@selector(stop)];
	}
}

- (void) rewind
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        [sourcePool.sources makeObjectsPerformSelector:@selector(rewind)];
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
		for(id<ALSoundSource> source in sourcePool.sources)
		{
			[source fadeTo:value duration:duration target:self selector:@selector(onFadeComplete:)];
		}
	}
}

- (void) onFadeComplete:(id<ALSoundSource>) source
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
		[sourcePool.sources makeObjectsPerformSelector:@selector(stopFade)];
	}
}

- (void) panTo:(float) value duration:(float) duration target:(id) target selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		[self stopPan];
		panCompleteTarget = target;
		panCompleteSelector = selector;
		
		currentPanCallbackCount = 0;
		expectedPanCallbackCount = [sourcePool.sources count];
		for(id<ALSoundSource> source in sourcePool.sources)
		{
			[source panTo:value duration:duration target:self selector:@selector(onPanComplete:)];
		}
	}
}

- (void) onPanComplete:(id<ALSoundSource>) source
{
	// Must always be synchronized
	@synchronized(self)
	{
		currentPanCallbackCount++;
		if(currentPanCallbackCount == expectedPanCallbackCount)
		{
			[panCompleteTarget performSelector:panCompleteSelector withObject:self];
		}
	}
}

- (void) stopPan
{
	// Must always be synchronized
	@synchronized(self)
	{
		[sourcePool.sources makeObjectsPerformSelector:@selector(stopPan)];
	}
}

- (void) pitchTo:(float) value duration:(float) duration target:(id) target selector:(SEL) selector
{
	// Must always be synchronized
	@synchronized(self)
	{
		[self stopPitch];
		pitchCompleteTarget = target;
		pitchCompleteSelector = selector;
		
		currentPitchCallbackCount = 0;
		expectedPitchCallbackCount = [sourcePool.sources count];
		for(id<ALSoundSource> source in sourcePool.sources)
		{
			[source pitchTo:value duration:duration target:self selector:@selector(onPitchComplete:)];
		}
	}
}

- (void) onPitchComplete:(id<ALSoundSource>) source
{
	// Must always be synchronized
	@synchronized(self)
	{
		currentPitchCallbackCount++;
		if(currentPitchCallbackCount == expectedPitchCallbackCount)
		{
			[pitchCompleteTarget performSelector:pitchCompleteSelector withObject:self];
		}
	}
}

- (void) stopPitch
{
	// Must always be synchronized
	@synchronized(self)
	{
		[sourcePool.sources makeObjectsPerformSelector:@selector(stopPitch)];
	}
}

- (void) stopActions
{
	// Must always be synchronized
	@synchronized(self)
	{
		[sourcePool.sources makeObjectsPerformSelector:@selector(stopActions)];
	}
}


- (void) clear
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        [sourcePool.sources makeObjectsPerformSelector:@selector(clear)];
	}
}

- (void) setDefaultsFromSource:(id<ALSoundSource>) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        defaultPitch = source.pitch;
        defaultGain = source.gain;
        defaultMaxDistance = source.maxDistance;
        defaultRolloffFactor = source.rolloffFactor;
        defaultReferenceDistance = source.referenceDistance;
        defaultMinGain = source.minGain;
        defaultMaxGain = source.maxGain;
        defaultConeOuterGain = source.coneOuterGain;
        defaultConeInnerAngle = source.coneInnerAngle;
        defaultConeOuterAngle = source.coneOuterAngle;
        defaultPosition = source.position;
        defaultVelocity = source.velocity;
        defaultDirection = source.direction;
        defaultSourceRelative = source.sourceRelative;
        defaultSourceType = source.sourceType;
        defaultLooping = source.looping;
        
        defaultsInitialized = YES;
    }
}

- (void) setDefaultsFromChannel:(ALChannelSource*) channel
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        defaultPitch = channel->defaultPitch;
        defaultGain = channel->defaultGain;
        defaultMaxDistance = channel->defaultMaxDistance;
        defaultRolloffFactor = channel->defaultRolloffFactor;
        defaultReferenceDistance = channel->defaultReferenceDistance;
        defaultMinGain = channel->defaultMinGain;
        defaultMaxGain = channel->defaultMaxGain;
        defaultConeOuterGain = channel->defaultConeOuterGain;
        defaultConeInnerAngle = channel->defaultConeInnerAngle;
        defaultConeOuterAngle = channel->defaultConeOuterAngle;
        defaultPosition = channel->defaultPosition;
        defaultVelocity = channel->defaultVelocity;
        defaultDirection = channel->defaultDirection;
        defaultSourceRelative = channel->defaultSourceRelative;
        defaultSourceType = channel->defaultSourceType;
        defaultLooping = channel->defaultLooping;
        
        defaultsInitialized = YES;
    }
}



- (void) resetToDefault
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        self.pitch = defaultPitch;
        self.gain = defaultGain;
        self.maxDistance = defaultMaxDistance;
        self.rolloffFactor = defaultRolloffFactor;
        self.referenceDistance = defaultReferenceDistance;
        self.minGain = defaultMinGain;
        self.maxGain = defaultMaxGain;
        // Disabled due to OpenAL default ConeOuterGain value issue
        // self.coneOuterGain = defaultConeOuterGain;
        self.coneInnerAngle = defaultConeInnerAngle;
        self.coneOuterAngle = defaultConeOuterAngle;
        self.position = defaultPosition;
        self.velocity = defaultVelocity;
        self.direction = defaultDirection;
        self.sourceRelative = defaultSourceRelative;
        sourceType = defaultSourceType;
        self.looping = defaultLooping;
    }
}



- (void) addSource:(id<ALSoundSource>) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        if(nil == source)
        {
            source = [ALSource source];
        }
        if(defaultsInitialized)
        {
            source.pitch = pitch;
            source.gain = gain;
            source.maxDistance = maxDistance;
            source.rolloffFactor = rolloffFactor;
            source.referenceDistance = referenceDistance;
            source.minGain = minGain;
            source.maxGain = maxGain;
            // Disabled due to OpenAL default ConeOuterGain value issue
            // source.coneOuterGain = coneOuterGain;
            source.coneInnerAngle = coneInnerAngle;
            source.coneOuterAngle = coneOuterAngle;
            source.position = position;
            source.velocity = velocity;
            source.direction = direction;
            source.sourceRelative = sourceRelative;
            source.looping = looping;
        }
        else
        {
            [self setDefaultsFromSource:source];
            [self resetToDefault];
        }
        [sourcePool addSource:source];
    }
}

- (id<ALSoundSource>) removeSource:(id<ALSoundSource>) source
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
        if(nil == source)
        {
            source = [sourcePool getFreeSource:YES];
            if(nil == source)
            {
                return nil;
            }
        }
        [[source retain] autorelease];
        [sourcePool removeSource:source];
    }
    
    return source;
}

- (ALChannelSource*) splitChannelWithSources:(unsigned int) numSources
{
    ALChannelSource* newChannel;

	OPTIONALLY_SYNCHRONIZED(self)
	{
        newChannel = [ALChannelSource channelWithSources:0];
        [newChannel setDefaultsFromChannel:self];
        [newChannel resetToDefault];
        for(unsigned int i = 0; i < numSources; i++)
        {
            id<ALSoundSource> source = [self removeSource:nil];
            if(nil == source)
            {
                break;
            }
            [newChannel addSource:source];
        }
    }

    return newChannel;
}

- (void) addChannel:(ALChannelSource*) channel
{
    id<ALSoundSource> source;
    
	OPTIONALLY_SYNCHRONIZED(self)
	{
        while (nil != (source = [channel removeSource:nil]))
        {
            [self addSource:source];
        }
    }
}

@end
