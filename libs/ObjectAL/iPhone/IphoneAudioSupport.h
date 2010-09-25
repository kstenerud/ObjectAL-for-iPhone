//
//  IphoneAudioSupport.h
//  ObjectAL
//
//  Created by Karl Stenerud on 19/12/09.
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
#import "SynthesizeSingleton.h"
#import "ALBuffer.h"


#pragma mark IphoneAudioSupport

/**
 * Provides iphone-specific audio support, including audio file loading, session management and
 * interrupt handling.
 *
 * <strong>Note:</strong> OpenAL is only able to play PCM (uncompressed) 8 bit or 16 bit (little
 * endian) audio files.  As such, the buffer loading routines will attempt to convert incompatible
 * sound files.  If you want to avoid the conversion cost, you can pre-convert your audio files
 * prior to adding them to your project. The <strong>afconvert</strong> command line tool is able
 * to do this conversion.
 *
 * Example: convert from a wav file to iPhone compatible, 16 bits per channel, 44100KHz:
 *
 * \code afconvert -f caff -d LEI16@@44100 sourcefile.wav destfile.caf \endcode
 *
 * Example: convert from a wav file to iPhone compatible, 8 bits per channel, 22050KHz:
 *
 * \code afconvert -f caff -d I8@@22050 sourcefile.wav destfile.caf \endcode
 */
@interface IphoneAudioSupport : NSObject
{
	/** Operation queue for asynchronous loading. */
	NSOperationQueue* operationQueue;

	UInt32 overrideAudioSessionCategory;

	bool handleInterruptions;
	bool allowIpod;
	bool useHardwareIfAvailable;
	bool honorSilentSwitch;
	
	bool audioSessionActive;

	/** Marks the overall sound engine as being suspended. */
	bool suspended;
	
	/** If true, BackgoundAudio was already suspended when the interrupt occurred. */
	bool backgroundAudioWasSuspended;
	
	/** If true, ObjectAL was already suspended when the interrupt occurred. */
	bool objectALWasSuspended;
	
	/** If true, the audio session was active when the interrupt occurred. */
	bool audioSessionWasActive;
	
	/** Dictionary mapping audio session error codes to human readable descriptions.
	 * Key: NSNumber, Value: NSString
	 */
	NSDictionary* audioSessionErrorCodes;

	/** Dictionary mapping ExtAudio error codes to human readable descriptions.
	 * Key: NSNumber, Value: NSString
	 */
	NSDictionary* extAudioErrorCodes;
}


#pragma mark Properties

/** Override for the audio session category selection.
 * If set to something other than 0, the "allowIpod", "useHardwareIfAvailable",
 * and "honorSilentSwitch" settings will be ignored, and the specified audio session
 * category will be used instead. <br>
 *
 * See the kAudioSessionProperty_AudioCategory property in the Apple developer
 * documentation for more info. <br>
 *
 * Default value: 0
 */
@property(readwrite,assign) UInt32 overrideAudioSessionCategory;

/** If YES, allow ipod music to continue playing (NOT SUPPORTED ON THE SIMULATOR).
 * Note: If this is enabled, and another app is playing music, background audio
 * playback will use the SOFTWARE codecs, NOT hardware. <br>
 *
 * If allowIpod = NO, the application will ALWAYS use hardware decoding. <br>
 *
 * @see useHardwareIfAvailable
 *
 * Default value: YES
 */
@property(readwrite,assign) bool allowIpod;

/** Determines what to do if no other application is playing audio and allowIpod = YES
 * (NOT SUPPORTED ON THE SIMULATOR). <br>
 *
 * If NO, the application will ALWAYS use software decoding.  The advantage to this is that
 * the user can background your application and then start audio playing from another
 * application.  If useHardwareIfAvailable = YES, the user won't be able to do this. <br>
 *
 * If this is set to YES, the application will use hardware decoding if no other application
 * is currently playing audio. However, no other application will be able to start playing
 * audio if it wasn't playing already. <br>
 *
 * Note: This switch has no effect if allowIpod = NO. <br>
 *
 * @see allowIpod
 *
 * Default value: YES
 */
@property(readwrite,assign) bool useHardwareIfAvailable;

/** If true, mute when backgrounded, screen locked, or the ringer switch is
 * turned off (NOT SUPPORTED ON THE SIMULATOR). <br>
 *
 * Default value: YES
 */
@property(readwrite,assign) bool honorSilentSwitch;

/** If true, automatically handle interruptions. <br>
 *
 * Default value: YES
 */
@property(readwrite,assign) bool handleInterruptions;

/** If true, another application (usually iPod) is playing music. */
@property(readonly) bool ipodPlaying;

/** If true, the audio session is active */
@property(readwrite,assign) bool audioSessionActive;

#pragma mark Object Management

/** Singleton implementation providing "sharedInstance" and "purgeSharedInstance" methods.
 *
 * <b>- (IphoneAudioSupport*) sharedInstance</b>: Get the shared singleton instance. <br>
 * <b>- (void) purgeSharedInstance</b>: Purge (deallocate) the shared instance.
 */
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(IphoneAudioSupport);


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
 * The buffer's name will be the fully qualified URL.
 *
 * See the class description note regarding sound file formats.
 *
 * @param url The URL of the file containing the audio data.
 * @return An ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferFromUrl:(NSURL*) url;

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


#pragma mark Utility

/** Get the corresponding URL for a file path.
 *
 * @param path the path to get a URL for.
 * @return the corresponding URL, or nil if one couldn't be gemerated.
 */
- (NSURL*) urlForPath:(NSString*) path;

@end
