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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "SoundSource.h"
#import "SoundSourcePool.h"
#import "ALContext.h"


#pragma mark ChannelSource

/**
 * A Sound source composed of other sources.
 * Property values are applied to all sources within the channel. <br>
 * Sounds will get played by any free sources within this channel. <br>
 * If all sources are busy when playback is requested, it will attempt to interrupt a source to free it for playback.
 */
@interface ChannelSource : NSObject <SoundSource>
{
	SoundSourcePool* sourcePool;
	ALContext* context;

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

	bool interruptible;
	bool muted;
	bool paused;
}


#pragma mark Properties

/** This source's owning context. */
@property(readonly) ALContext* context;

/** All sources being used by this channel.  Do not modify! */
@property(readonly) SoundSourcePool* sourcePool;


#pragma mark Object Management

/** Create a channel with a number of sources.
 *
 * @param numSources the number of sources to create in this channel.
 * @return A new channel.
 */
+ (id) channelWithSources:(int) numSources;

/** Initialize a channel with a number of sources.
 *
 * @param numSources the number of sources to create in this channel.
 * @return The initialized channel.
 */
- (id) initWithSources:(int) numSources;

@end
