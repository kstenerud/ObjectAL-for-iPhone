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
	}
	return self;
}


#pragma mark Properties

@synthesize context;

- (float) gain
{
	return [ALWrapper getListenerf:AL_GAIN];
}

- (void) setGain:(float) value
{
	[ALWrapper listenerf:AL_GAIN value:value];
}

- (ALOrientation) orientation
{
	ALOrientation result;
	[ALWrapper getListenerfv:AL_ORIENTATION values:(float*)&result];
	return result;
}

- (void) setOrientation:(ALOrientation) value
{
	[ALWrapper listenerfv:AL_ORIENTATION values:(float*)&value];
}

- (ALPoint) position
{
	ALPoint result;
	[ALWrapper getListener3f:AL_POSITION v1:&result.x v2:&result.y v3:&result.z];
	return result;
}

- (void) setPosition:(ALPoint) value
{
	[ALWrapper listener3f:AL_POSITION v1:value.x v2:value.y v3:value.z];
}

- (ALVector) velocity
{
	ALVector result;
	[ALWrapper getListener3f:AL_VELOCITY v1:&result.x v2:&result.y v3:&result.z];
	return result;
}

- (void) setVelocity:(ALVector) value
{
	[ALWrapper listener3f:AL_VELOCITY v1:value.x v2:value.y v3:value.z];
}

@end
