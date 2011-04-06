//
//  ChannelSource.h
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

#import "ALSoundSource.h"
#import "ALSoundSourcePool.h"
#import "ALContext.h"


#pragma mark ALChannelSource

/**
 * A Sound source composed of other sources.
 * Property values are applied to all sources within the channel. <br>
 * Sounds will get played by any free sources within this channel. <br>
 * If all sources are busy when playback is requested, it will attempt to interrupt a source
 * to free it for playback.
 */
@interface ALChannelSource : NSObject <ALSoundSource>
{
    /** Pool holding the actual sources */
	ALSoundSourcePool* sourcePool;
	ALContext* context;
    
    /** If YES, the defaults of this channel have been initialized */
    bool defaultsInitialized;

	float pitch;
	float gain;
	float maxDistance;
	float rolloffFactor;
	float referenceDistance;
	float minGain;
	float maxGain;
	float coneOuterGain;
	float coneInnerAngle;
	float coneOuterAngle;
	
	ALPoint position;
	ALVector velocity;
	ALVector direction;
	
	int sourceRelative;
	int sourceType;
	bool looping;

    /** Default pitch */
    float defaultPitch;
    /** Default gain */
	float defaultGain;
    /** Default max distance */
	float defaultMaxDistance;
    /** Default rolloff factor */
	float defaultRolloffFactor;
    /** Default reference distance */
	float defaultReferenceDistance;
    /** Default min gain */
	float defaultMinGain;
    /** Default max gain */
	float defaultMaxGain;
    /** Default cone outer gain */
	float defaultConeOuterGain;
    /** Default cone inner angle */
	float defaultConeInnerAngle;
    /** Default cone outer angle */
	float defaultConeOuterAngle;
    /** Default position */
	ALPoint defaultPosition;
    /** Default veloxity */
	ALVector defaultVelocity;
    /** Default direction */
	ALVector defaultDirection;
	/** Default source relative */
	int defaultSourceRelative;
    /** Default source type */
	int defaultSourceType;
    /** Default looping */
	bool defaultLooping;
    

	bool interruptible;
	bool muted;
	bool paused;

	/** Target to inform when the current fade operation completes. */
	id fadeCompleteTarget;
	
	/** Selector to call when the current fade operation completes. */
	SEL fadeCompleteSelector;
	
	/** The expected number of sources that will callback when fading completes */
	int expectedFadeCallbackCount;

	/** The actual number of sources that have called back */
	int currentFadeCallbackCount;
	

	/** Target to inform when the current pan operation completes. */
	id panCompleteTarget;
	
	/** Selector to call when the current pan operation completes. */
	SEL panCompleteSelector;
	
	/** The expected number of sources that will callback when panning completes */
	int expectedPanCallbackCount;
	
	/** The actual number of sources that have called back */
	int currentPanCallbackCount;


	
	/** Target to inform when the current pitch operation completes. */
	id pitchCompleteTarget;
	
	/** Selector to call when the current pitch operation completes. */
	SEL pitchCompleteSelector;
	
	/** The expected number of sources that will callback when pitch op completes */
	int expectedPitchCallbackCount;
	
	/** The actual number of sources that have called back */
	int currentPitchCallbackCount;
}


#pragma mark Properties

/** This source's owning context. */
@property(readonly) ALContext* context;

/** All sources being used by this channel. Do not modify! */
@property(readonly) ALSoundSourcePool* sourcePool;

/** The number of sources reserved by this channel. */
@property(readwrite,assign,nonatomic) unsigned int reservedSources;

#pragma mark Object Management

/** Create a channel with a number of sources.
 *
 * @param reservedSources the number of sources to reserve for this channel.
 * @return A new channel.
 */
+ (id) channelWithSources:(unsigned int) reservedSources;

/** Initialize a channel with a number of sources.
 *
 * @param reservedSources the number of sources to reserve for this channel.
 * @return The initialized channel.
 */
- (id) initWithSources:(unsigned int) reservedSources;

/** Set this channel's default values from those in the specified source.
 *
 * @param source the source to set default values from.
 */
- (void) setDefaultsFromSource:(id<ALSoundSource>) source;

/** Reset all sources in this channel to their default state.
 */
- (void) resetToDefault;

/** Add a source to this channel.
 *
 * @param source The source to add.
 */
- (void) addSource:(id<ALSoundSource>) source;

/** Remove a source from the channel.
 *
 * @param source The source to remove. If nil, remove any source.
 * @return The source that was removed.
 */
- (id<ALSoundSource>) removeSource:(id<ALSoundSource>) source;

/** Split the specified number of sources from this channel, creating a new
 * channel.
 *
 * @param numSources The number of sources to split off
 * @return A new channel with the split-off sources.
 */
- (ALChannelSource*) splitChannelWithSources:(unsigned int) numSources;

/** Absorb another channel's sources into this one. All of the channel's sources
 * will be moved into this channel.
 *
 * @param channel The channel to absorb sources from.
 */
- (void) addChannel:(ALChannelSource*) channel;


@end
