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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OpenALManager.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "MutableArray-WeakReferences.h"
#import "IphoneAudioSupport.h"


#pragma mark OpenALManager

@implementation OpenALManager


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OpenALManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Make sure IphoneAudioSupport is initialized.
		[IphoneAudioSupport sharedInstance];
		
		devices = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:5] retain];
		suspendedContexts = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:30] retain];
	}
	return self;
}

- (void) dealloc
{
	self.currentContext = nil;
	[suspendedContexts release];
	[devices release];
	
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
		if(context != currentContext)
		{
			currentContext = context;
			[ALWrapper makeContextCurrent:currentContext.context deviceReference:currentContext.device.device];
		}
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
		[ALWrapper setMixerOutputDataRate:frequency];
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
		if(value != suspended)
		{
			suspended = value;
			if(suspended)
			{
				[ALWrapper makeContextCurrent:nil];
				/*  alcSuspendContext appears to be a no-op
				 for(ALDevice* device in devices)
				 {
				 for(ALContext* context in device.contexts)
				 {
				 if(!context.suspended)
				 {
				 [suspendedContexts addObject:context];
				 [ALWrapper suspendContext:context.context];
				 }
				 }
				 }
				 */
			}
			else
			{
				/*
				 for(ALContext* context in suspendedContexts)
				 {
				 [ALWrapper makeContextCurrent:context.context];
				 [context process];
				 }
				 [suspendedContexts removeAllObjects];
				 */
				if(nil != currentContext)
				{
					[ALWrapper makeContextCurrent:currentContext.context deviceReference:currentContext.device.device];
				}
			}
		}
	}
}

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
