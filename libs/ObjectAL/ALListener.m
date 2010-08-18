//
//  ALListener.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-07.
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

#import "ALListener.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"


@implementation ALListener

#pragma mark Object Management

+ (id) listenerForContext:(ALContext*) context
{
	return [[[self alloc] initWithContext:context] autorelease];
}

- (id) initWithContext:(ALContext*) contextIn
{
	if(nil != (self = [super init]))
	{
		context = contextIn;
		gain = 1.0;
	}
	return self;
}


#pragma mark Properties

@synthesize context;

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
		float resultingGain = muted ? 0 : gain;
		self.gain = resultingGain;
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
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getListenerfv:AL_ORIENTATION values:(float*)&result];
	}
	return result;
}

- (void) setOrientation:(ALOrientation) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		[ALWrapper listenerfv:AL_ORIENTATION values:(float*)&value];
	}
}

- (ALPoint) position
{
	ALPoint result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getListener3f:AL_POSITION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setPosition:(ALPoint) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		[ALWrapper listener3f:AL_POSITION v1:value.x v2:value.y v3:value.z];
	}
}

- (ALVector) velocity
{
	ALVector result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[ALWrapper getListener3f:AL_VELOCITY v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setVelocity:(ALVector) value
{
	OPTIONALLY_SYNCHRONIZED_STRUCT_OP(self)
	{
		[ALWrapper listener3f:AL_VELOCITY v1:value.x v2:value.y v3:value.z];
	}
}

@end
