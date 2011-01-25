//
//  OALTools.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-12-19.
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

#import <Foundation/Foundation.h>


/**
 * Miscellaneous tools used by ObjectAL.
 */
@interface OALTools : NSObject
{
}

/** Returns the URL corresponding to the specified path.
 * If the path is not absolute (starts with a "/"), this method will look for
 * the file in the application's main bundle.
 *
 * @param path The path to convert to a URL.
 * @return The corresponding URL or nil if a URL could not be formed.
 */
+ (NSURL*) urlForPath:(NSString*) path;

/** Notify an error if the specified ExtAudio error code indicates an error.
 * This will log the error and also potentially post an audio error notification
 * (OALAudioErrorNotification) if it is suspected that this error is a result of
 * the audio session getting corrupted.
 *
 * @param errorCode: The error code returned from an OS call.
 * @param function: The function name where the error occurred.
 * @param description: A printf-style description of what happened.
 */
+ (void) notifyExtAudioError:(OSStatus)errorCode
				 function:(const char*) function
			  description:(NSString*) description, ...;

/** Notify an error if the specified AudioSession error code indicates an error.
 * This will log the error and also potentially post an audio error notification
 * (OALAudioErrorNotification) if it is suspected that this error is a result of
 * the audio session getting corrupted.
 *
 * @param errorCode: The error code returned from an OS call.
 * @param function: The function name where the error occurred.
 * @param description: A printf-style description of what happened.
 */
+ (void) notifyAudioSessionError:(OSStatus)errorCode
					 function:(const char*) function
				  description:(NSString*) description, ...;

@end
