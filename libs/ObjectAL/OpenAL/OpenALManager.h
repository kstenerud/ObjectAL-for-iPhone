//
//  OpenALManager.h
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

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "ALContext.h"


#pragma mark OpenALManager

/**
 * Manager class for OpenAL objects (ObjectAL).
 * Keeps track of devices that have been opened, and allows high level OpenAL management. <br>
 * Provides methods for loading ALBuffer objects from audio files. <br>
 * The OpenAL 1.1 specification is available at
 * http://connect.creativelabs.com/openal/Documentation <br>
 * Be sure to read through it (especially the part about distance models) as ObjectAL follows the
 * OpenAL object model. <br>
 *
 * Alternatively, you may opt to use OALSimpleAudio for a simpler interface.
 */
@interface OpenALManager : NSObject <OALSuspendManager>
{
	ALContext* currentContext; // WEAK reference
	
	/** All opened devices */
	NSMutableArray* devices;
	
	/** Handles suspending and interrupting for this object. */
	OALSuspendHandler* suspendHandler;

	/** Operation queue for asynchronous loading. */
	NSOperationQueue* operationQueue;
}


#pragma mark Properties

/** List of available playback devices (NSString*). */
@property(readonly) NSArray* availableDevices;

/** List of available capture devices (NSString*). */
@property(readonly) NSArray* availableCaptureDevices;

/** The current context (some context operations require the context to be the "current" one).
 */
@property(readwrite,assign) ALContext* currentContext;

/** Name of the default capture device. */
@property(readonly) NSString* defaultCaptureDeviceSpecifier;

/** Name of the default playback device. */
@property(readonly) NSString* defaultDeviceSpecifier;

/** List of all open devices (ALDevice*). */
@property(readonly) NSArray* devices;

/** The frequency of the output mixer. */
@property(readwrite,assign) ALdouble mixerOutputFrequency;


#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (OpenALManager*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(OpenALManager);

/** Close any OS resources in use by this object.
 * Any operations called on this object after closing will likely fail.
 */
- (void) close;


#pragma mark Buffers

/** Load an OpenAL buffer with the contents of an audio file.
 * The buffer's name will be the fully qualified URL of the path.
 *
 * See the class description note regarding sound file formats.
 *
 * @param filePath The path of the file containing the audio data.
 * @return An ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferFromFile:(NSString*) filePath;

/** Load an OpenAL buffer with the contents of an audio file.
 * The buffer's name will be the fully qualified URL of the path.
 *
 * See the class description note regarding sound file formats.
 *
 * @param filePath The path of the file containing the audio data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @return An ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferFromFile:(NSString*) filePath reduceToMono:(bool) reduceToMono;

/** Load an OpenAL buffer with the contents of an audio file.
 * The buffer's name will be the fully qualified URL.
 *
 * See the class description note regarding sound file formats.
 *
 * @param url The URL of the file containing the audio data.
 * @return An ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferFromUrl:(NSURL*) url;

/** Load an OpenAL buffer with the contents of an audio file.
 * The buffer's name will be the fully qualified URL.
 *
 * See the class description note regarding sound file formats.
 *
 * @param url The URL of the file containing the audio data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @return An ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferFromUrl:(NSURL*) url reduceToMono:(bool) reduceToMono;

/** Load an OpenAL buffer with the contents of an audio file asynchronously.
 * This method will schedule a request to have the buffer created and filled, and then call the
 * specified selector with the newly created buffer. <br>
 * The buffer's name will be the fully qualified URL of the path. <br>
 * Returns the fully qualified URL of the path, which you can match up to the buffer name in your
 * callback method.
 *
 * See the class description note regarding sound file formats.
 *
 * @param filePath The path of the file containing the audio data.
 * @param target The target to call when the buffer is loaded.
 * @param selector The selector to invoke when the buffer is loaded.
 * @return The fully qualified URL of the path.
 */
- (NSString*) bufferAsyncFromFile:(NSString*) filePath target:(id) target selector:(SEL) selector;

/** Load an OpenAL buffer with the contents of an audio file asynchronously.
 * This method will schedule a request to have the buffer created and filled, and then call the
 * specified selector with the newly created buffer. <br>
 * The buffer's name will be the fully qualified URL of the path. <br>
 * Returns the fully qualified URL of the path, which you can match up to the buffer name in your
 * callback method.
 *
 * See the class description note regarding sound file formats.
 *
 * @param filePath The path of the file containing the audio data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @param target The target to call when the buffer is loaded.
 * @param selector The selector to invoke when the buffer is loaded.
 * @return The fully qualified URL of the path.
 */
- (NSString*) bufferAsyncFromFile:(NSString*) filePath
					 reduceToMono:(bool) reduceToMono
						   target:(id) target
						 selector:(SEL) selector;

/** Load an OpenAL buffer with the contents of a URL asynchronously.
 * This method will schedule a request to have the buffer created and filled, and then call the
 * specified selector with the newly created buffer. <br>
 * The buffer's name will be the fully qualified URL. <br>
 * Returns the fully qualified URL, which you can match up to the buffer name in your callback
 * method.
 *
 * See the class description note regarding sound file formats.
 *
 * @param url The URL of the file containing the audio data.
 * @param target The target to call when the buffer is loaded.
 * @param selector The selector to invoke when the buffer is loaded.
 * @return The fully qualified URL of the path.
 */
- (NSString*) bufferAsyncFromUrl:(NSURL*) url target:(id) target selector:(SEL) selector;

/** Load an OpenAL buffer with the contents of a URL asynchronously.
 * This method will schedule a request to have the buffer created and filled, and then call the
 * specified selector with the newly created buffer. <br>
 * The buffer's name will be the fully qualified URL. <br>
 * Returns the fully qualified URL, which you can match up to the buffer name in your callback
 * method.
 *
 * See the class description note regarding sound file formats.
 *
 * @param url The URL of the file containing the audio data.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @param target The target to call when the buffer is loaded.
 * @param selector The selector to invoke when the buffer is loaded.
 * @return The fully qualified URL of the path.
 */
- (NSString*) bufferAsyncFromUrl:(NSURL*) url
					reduceToMono:(bool) reduceToMono
						  target:(id) target
						selector:(SEL) selector;


#pragma mark Utility

/** Clear all references to sound data from ALL buffers, managed or not.
 */
- (void) clearAllBuffers;


#pragma mark Internal Use

/** (INTERNAL USE) Notify that a device is initializing.
 */
- (void) notifyDeviceInitializing:(ALDevice*) device;

/** (INTERNAL USE) Notify that a device is deallocating.
 */
- (void) notifyDeviceDeallocating:(ALDevice*) device;

@end
