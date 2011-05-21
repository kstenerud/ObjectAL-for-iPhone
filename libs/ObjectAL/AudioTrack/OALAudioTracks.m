//
//  OALAudioTracks.m
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALAudioTracks.h"
#import "NSMutableArray+WeakReferences.h"
#import "ObjectALMacros.h"
#import "OALAudioSession.h"
#import "IOSVersion.h"


SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALAudioTracks);


/**
 * (INTERNAL USE) Private methods for OALAudioTracks.
 */
@interface OALAudioTracks (Private)

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

/** (INTERNAL USE) Read deviceCurrentTime from an audio player
 * as a workaround for a bug in iOS devices that causes the value
 * to reset to 0 in certain circumstances.
 */
- (void) pollDeviceTime;

@end


#pragma mark OALAudioTracks

@implementation OALAudioTracks

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALAudioTracks);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);

		suspendHandler = [[OALSuspendHandler alloc] initWithTarget:nil selector:nil];

		tracks = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:10];
		
		[[OALAudioSession sharedInstance] addSuspendListener:self];

		if([IOSVersion sharedInstance].version >= 4.0)
		{
            // Need to constantly poll deviceCurrentTime or else it resets to 0
            // on devices (doesn't happen in simulator).
            deviceTimePoller = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(pollDeviceTime)
                                                              userInfo:nil
                                                               repeats:YES];
        }
    }
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	[[OALAudioSession sharedInstance] removeSuspendListener:self];
    [deviceTimePoller invalidate];

	[self closeOSResources];

	[tracks release];
	[suspendHandler release];
	
	[super dealloc];
}

- (void) closeOSResources
{
	// Not directly holding any OS resources.
}

- (void) close
{
	@synchronized(self)
	{
		if(nil != tracks)
		{
			[tracks makeObjectsPerformSelector:@selector(close)];
			[tracks release];
			tracks = nil;
			
			[self closeOSResources];
		}
	}
}


#pragma mark Properties

@synthesize tracks;

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
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		paused = value;
		for(OALAudioTrack* track in tracks)
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
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		muted = value;
		for(OALAudioTrack* track in tracks)
		{
			track.muted = muted;
		}
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


#pragma mark Internal Use

- (void) notifyTrackInitializing:(OALAudioTrack*) track
{
	@synchronized(self)
	{
		[tracks addObject:track];
	}
}

- (void) notifyTrackDeallocating:(OALAudioTrack*) track
{
	@synchronized(self)
	{
		[tracks removeObject:track];
	}
}

- (void) pollDeviceTime
{
	@synchronized(self)
	{
        // Only actually have to poll a single track's value to avoid the bug.
        if([tracks count] > 0)
        {
            [[tracks objectAtIndex:0] deviceCurrentTime];
        }
    }
}

@end
