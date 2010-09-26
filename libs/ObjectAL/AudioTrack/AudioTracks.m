//
//  AudioTracks.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-18.
//
// Copyright 2010 Karl Stenerud
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

#import "AudioTracks.h"
#import "MutableArray-WeakReferences.h"
#import "ObjectALMacros.h"
#import "IphoneAudioSupport.h"


#pragma mark AudioTracks

@implementation AudioTracks

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(AudioTracks);

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Make sure IphoneAudioSupport is initialized.
		[IphoneAudioSupport sharedInstance];

		tracks = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:10] retain];
	}
	return self;
}

- (void) dealloc
{
	[tracks release];
	[super dealloc];
}


#pragma mark Properties

@synthesize tracks;

- (bool) suspended
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return suspended;
	}
}

- (void) setSuspended:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		suspended = value;
		for(AudioTrack* track in tracks)
		{
			track.suspended = suspended;
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
		for(AudioTrack* track in tracks)
		{
			track.paused = paused;
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
		for(AudioTrack* track in tracks)
		{
			track.muted = muted;
		}
	}
}


#pragma mark Internal Use

- (void) notifyTrackInitializing:(AudioTrack*) track
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[tracks addObject:track];
	}
}

- (void) notifyTrackDeallocating:(AudioTrack*) track
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[tracks removeObject:track];
	}
}

@end
