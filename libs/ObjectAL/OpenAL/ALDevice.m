//
//  ALDevice.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-09.
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

#import "ALDevice.h"
#import "NSMutableArray+WeakReferences.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "OpenALManager.h"


/**
 * (INTERNAL USE) Private methods for ALDevice.
 */
@interface ALDevice (Private)

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

@end


@implementation ALDevice

#pragma mark Object Management

+ (id) deviceWithDeviceSpecifier:(NSString*) deviceSpecifier
{
	return [[[self alloc] initWithDeviceSpecifier:deviceSpecifier] autorelease];
}

- (id) initWithDeviceSpecifier:(NSString*) deviceSpecifier
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init device %@", self, deviceSpecifier);

		device = [ALWrapper openDevice:deviceSpecifier];
		if(nil == device)
		{
			OAL_LOG_ERROR(@"%@: Failed to init device %@. Returning nil", self, deviceSpecifier);
			[self release];
			return nil;
		}

		suspendHandler = [[OALSuspendHandler alloc] initWithTarget:nil selector:nil];
		
		contexts = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:5];
			
		[[OpenALManager sharedInstance] notifyDeviceInitializing:self];
		[[OpenALManager sharedInstance] addSuspendListener:self];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);

	[[OpenALManager sharedInstance] removeSuspendListener:self];
	[[OpenALManager sharedInstance] notifyDeviceDeallocating:self];

	[self closeOSResources];
	
	[contexts release];
	[suspendHandler release];

	[super dealloc];
}

- (void) closeOSResources
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != device)
		{
			[ALWrapper closeDevice:device];
			device = nil;
		}
	}
}

- (void) close
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != contexts)
		{
			[contexts makeObjectsPerformSelector:@selector(close)];
			[contexts release];
			contexts = nil;

			[self closeOSResources];
		}
	}
}


#pragma mark Properties

@synthesize contexts;

@synthesize device;

- (NSArray*) extensions
{
	return [ALWrapper getSpaceSeparatedStringList:device attribute:ALC_EXTENSIONS];
}

- (int) majorVersion
{
	return [ALWrapper getInteger:device attribute:ALC_MAJOR_VERSION];
}

- (int) minorVersion
{
	return [ALWrapper getInteger:device attribute:ALC_MINOR_VERSION];
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


#pragma mark Extensions

- (bool) isExtensionPresent:(NSString*) name
{
	return [ALWrapper isExtensionPresent:device name:name];
}

- (void*) getProcAddress:(NSString*) functionName
{
	return [ALWrapper getProcAddress:device name:functionName];
}


#pragma mark Utility

- (void) clearBuffers
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		for(ALContext* context in contexts)
		{
			[context clearBuffers];
		}
	}
}


#pragma mark Internal Use

- (void) notifyContextInitializing:(ALContext*) context
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[contexts addObject:context];
	}
}

- (void) notifyContextDeallocating:(ALContext*) context
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if([OpenALManager sharedInstance].currentContext == context)
		{
			[OpenALManager sharedInstance].currentContext = nil;
		}
		[contexts removeObject:context];
	}
}

@end
