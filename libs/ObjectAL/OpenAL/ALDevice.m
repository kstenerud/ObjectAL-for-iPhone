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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALDevice.h"
#import "ALWrapper.h"
#import "ObjectALMacros.h"
#import "MutableArray-WeakReferences.h"
#import "IphoneAudioSupport.h"
#import "OpenALManager.h"


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
		// Make sure IphoneAudioSupport is initialized.
		[IphoneAudioSupport sharedInstance];

		if(nil != (device = [ALWrapper openDevice:deviceSpecifier]))
		{
			contexts = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:5] retain];
			
			[[OpenALManager sharedInstance] notifyDeviceInitializing:self];
		}
	}
	return self;
}

- (void) dealloc
{
	[[OpenALManager sharedInstance] notifyDeviceDeallocating:self];
	[contexts release];
	[ALWrapper closeDevice:device];

	[super dealloc];
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
		[contexts removeObject:context];
	}
}

@end
