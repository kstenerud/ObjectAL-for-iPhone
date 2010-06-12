//
//  ALCaptureDevice.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-01-11.
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

#import "ALCaptureDevice.h"
#import "ALWrapper.h"


@implementation ALCaptureDevice

#pragma mark Object Management

+ (id) deviceWithDeviceSpecifier:(NSString*) deviceSpecifier
					   frequency:(ALCuint) frequency
						  format:(ALCenum) format
					  bufferSize:(ALCsizei) bufferSize
{
	return [[[self alloc] initWithDeviceSpecifier:deviceSpecifier
										frequency:frequency
										   format:format
									   bufferSize:bufferSize] autorelease];
}

- (id) initWithDeviceSpecifier:(NSString*) deviceSpecifier
					 frequency:(ALCuint) frequency
						format:(ALCenum) format
					bufferSize:(ALCsizei) bufferSize
{
	if(nil != (self = [super init]))
	{
		device = [ALWrapper openCaptureDevice:deviceSpecifier
									frequency:frequency
									   format:format
								   bufferSize:bufferSize];
	}
	return self;
}

- (void) dealloc
{
	[ALWrapper closeDevice:device];
	
	[super dealloc];
}


#pragma mark Properties

@synthesize device;

- (int) captureSamples
{
	return [ALWrapper getInteger:device attribute:ALC_CAPTURE_SAMPLES];
}

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


#pragma mark Audio Capture

- (bool) moveSamples:(ALCsizei) numSamples toBuffer:(ALCvoid*) buffer
{
	return [ALWrapper captureSamples:device buffer:buffer numSamples:numSamples];
}

- (bool) startCapture
{
	return [ALWrapper startCapture:device];
}

- (bool) stopCapture
{
	return [ALWrapper stopCapture:device];
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


@end
