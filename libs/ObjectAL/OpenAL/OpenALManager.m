//
//  OpenALManager.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-25.
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

#import "OpenALManager.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "NSMutableArray+WeakReferences.h"
#import "OALAudioSupport.h"


@interface ALDevice (Interrupts)

- (void) setInterrupted:(bool) value;

@end


#pragma mark OpenALManager

@implementation OpenALManager


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OpenALManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);
		// Make sure OALAudioSupport is initialized.
		[OALAudioSupport sharedInstance];
		
		devices = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:5] retain];
		suspendLock = [[SuspendLock lockWithTarget:self
									  lockSelector:@selector(onSuspend)
									unlockSelector:@selector(onUnsuspend)] retain];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	self.currentContext = nil;
	[devices release];
	[suspendLock release];
	
	[super dealloc];
}


#pragma mark Properties

- (NSArray*) availableCaptureDevices
{
	return [ALWrapper getNullSeparatedStringList:nil attribute:ALC_CAPTURE_DEVICE_SPECIFIER];
}

- (NSArray*) availableDevices
{
	return [ALWrapper getNullSeparatedStringList:nil attribute:ALC_DEVICE_SPECIFIER];
}

- (ALContext*) currentContext
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return currentContext;
	}
}

- (void) setCurrentContext:(ALContext *) context
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		currentContext = context;
		[ALWrapper makeContextCurrent:currentContext.context deviceReference:currentContext.device.device];
	}
}

- (NSString*) defaultCaptureDeviceSpecifier
{
	return [ALWrapper getString:nil attribute:ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER];
}

- (NSString*) defaultDeviceSpecifier
{
	return [ALWrapper getString:nil attribute:ALC_DEFAULT_DEVICE_SPECIFIER];
}

@synthesize devices;

- (ALdouble) mixerOutputFrequency
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return [ALWrapper getMixerOutputDataRate];
	}
}

- (void) setMixerOutputFrequency:(ALdouble) frequency
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(suspendLock.locked)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper setMixerOutputDataRate:frequency];
	}
}

/** Called by SuspendLock to suspend this object.
 */
- (void) onSuspend
{
	[ALWrapper makeContextCurrent:nil];
}

/** Called by SuspendLock to unsuspend this object.
 */
- (void) onUnsuspend
{
	[ALWrapper makeContextCurrent:currentContext.context
				  deviceReference:currentContext.device.device];
}

- (bool) suspended
{
	// No need to synchronize since SuspendLock does that already.
	return suspendLock.suspendLock;
}

- (void) setSuspended:(bool) value
{
	// Ensure setting/resetting occurs in opposite order
	if(value)
	{
		for(ALDevice* device in devices)
		{
			device.suspended = value;
		}
	}

	// No need to synchronize since SuspendLock does that already.
	suspendLock.suspendLock = value;
	
	// Ensure setting/resetting occurs in opposite order
	if(!value)
	{
		for(ALDevice* device in devices)
		{
			device.suspended = value;
		}
	}
}

- (bool) interrupted
{
	// No need to synchronize since SuspendLock does that already.
	return suspendLock.interruptLock;
}

- (void) setInterrupted:(bool) value
{
	// Ensure setting/resetting occurs in opposing order
	if(value)
	{
		for(ALDevice* device in devices)
		{
			device.interrupted = value;
		}
	}

	// No need to synchronize since SuspendLock does that already.
	suspendLock.interruptLock = value;

	// Ensure setting/resetting occurs in opposing order
	if(!value)
	{
		for(ALDevice* device in devices)
		{
			device.interrupted = value;
		}
	}
}



#pragma mark Utility

- (void) clearAllBuffers
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(ALDevice* device in devices)
		{
			[device clearBuffers];
		}
	}
}

#pragma mark Internal Use

- (void) notifyDeviceInitializing:(ALDevice*) device
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[devices addObject:device];
	}
}

- (void) notifyDeviceDeallocating:(ALDevice*) device
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[devices removeObject:device];
	}
}

@end
