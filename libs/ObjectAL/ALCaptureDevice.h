//
//  ALCaptureDevice.h
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

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>


#pragma mark ALCaptureDevice

/**
 * *UNIMPLEMENTED FOR IPHONE* An OpenAL device for capturing sound data.
 * Note: This functionality is NOT implemented in iPhone's OpenAL! <br>
 * This class is a placeholder in case such functionality is added in a future iPhone SDK.
 */
@interface ALCaptureDevice : NSObject
{
	ALCdevice* device;
}


#pragma mark Properties

/** The number of capture samples available. */
@property(readonly) int captureSamples;

/** The OpenAL device pointer. */
@property(readonly) ALCdevice* device;

/** List of strings describing all extensions available on this device (NSString*). */
@property(readonly) NSArray* extensions;

/** The specification revision for this implementation (major version). */
@property(readonly) int majorVersion;

/** The specification revision for this implementation (minor version). */
@property(readonly) int minorVersion;


#pragma mark Object Management

/** Open the specified device.
 *
 * @param deviceSpecifier The name of the device to open (nil = default device).
 * @param frequency The frequency to capture at.
 * @param format The audio format to capture as.
 * @param bufferSize The size of buffer that the device must allocate for audio capture.
 * @return A new capture device.
 */
+ (id) deviceWithDeviceSpecifier:(NSString*) deviceSpecifier
					   frequency:(ALCuint) frequency
						  format:(ALCenum) format
					  bufferSize:(ALCsizei) bufferSize;

/** Open the specified device.
 *
 * @param deviceSpecifier The name of the device to open (nil = default device).
 * @param frequency The frequency to capture at.
 * @param format The audio format to capture as.
 * @param bufferSize The size of buffer that the device must allocate for audio capture.
 * @return The initialized capture device.
 */
- (id) initWithDeviceSpecifier:(NSString*) deviceSpecifier
					 frequency:(ALCuint) frequency
						format:(ALCenum) format
					bufferSize:(ALCsizei) bufferSize;


#pragma mark Audio Capture

/** Start capturing samples.
 *
 * @return TRUE if the operation was successful.
 */
- (bool) startCapture;

/** Stop capturing samples.
 *
 * @return TRUE if the operation was successful.
 */
- (bool) stopCapture;

/** Move captured samples to the specified buffer.
 * This method will fail if less than the specified number of samples have been captured.
 *
 * @param numSamples The number of samples to move.
 * @param buffer the buffer to move the samples into.
 * @return TRUE if the operation was successful.
 */
- (bool) moveSamples:(ALCsizei) numSamples toBuffer:(ALCvoid*) buffer;


#pragma mark Extensions

/** Check if the specified extension is present.
 *
 * @param name The name of the extension to check.
 * @return TRUE if the extension is present.
 */
- (bool) isExtensionPresent:(NSString*) name;

/** Get the address of the specified procedure (C function address).
 *
 * @param functionName The name of the procedure to get.
 * @return the procedure's address, or NULL if it wasn't found.
 */
- (void*) getProcAddress:(NSString*) functionName;


@end
