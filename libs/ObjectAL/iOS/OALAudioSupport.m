//
//  OALAudioSupport.m
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OALAudioSupport.h"
#import "ObjectALMacros.h"
#import <AudioToolbox/AudioToolbox.h>
#import "OALAudioTracks.h"
#import "OpenALManager.h"
//#import <UIKit/UIKit.h>
#import "OALInterruptAPI.h"


ADD_INTERRUPT_API(OALAudioSupport);
ADD_INTERRUPT_API(OpenALManager);
ADD_INTERRUPT_API(OALAudioTracks);

#define kMaxSessionActivationRetries 40

/** Dictionary mapping audio session error codes to human readable descriptions.
 * Key: NSNumber, Value: NSString
 */
NSDictionary* audioSessionErrorCodes = nil;

/** Dictionary mapping ExtAudio error codes to human readable descriptions.
 * Key: NSNumber, Value: NSString
 */
NSDictionary* extAudioErrorCodes = nil;


#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for loading audio files asynchronously.
 */
@interface OAL_AsyncALBufferLoadOperation: NSOperation
{
	/** The URL of the sound file to play */
	NSURL* url;
	/** If true, load the sound as mono */
	bool mono;
	/** The target to inform when the operation completes */
	id target;
	/** The selector to call when the operation completes */
	SEL selector;
}

/** (INTERNAL USE) Create a new Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param mono If true, convert the sound to mono.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
+ (id) operationWithUrl:(NSURL*) url
				   mono:(bool) mono
				 target:(id) target
			   selector:(SEL) selector;

/** (INTERNAL USE) Initialize an Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param mono If true, convert the sound to mono.
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
- (id) initWithUrl:(NSURL*) url
			  mono:(bool) mono
			target:(id) target
		  selector:(SEL) selector;

@end

@implementation OAL_AsyncALBufferLoadOperation

+ (id) operationWithUrl:(NSURL*) url
				   mono:(bool) mono
				 target:(id) target
			   selector:(SEL) selector
{
	return [[[self alloc] initWithUrl:url
								 mono:mono
							   target:target
							 selector:selector] autorelease];
}

- (id) initWithUrl:(NSURL*) urlIn
			  mono:(bool) monoIn
			target:(id) targetIn
		  selector:(SEL) selectorIn
{
	if(nil != (self = [super init]))
	{
		url = [urlIn retain];
		mono = monoIn;
		target = targetIn;
		selector = selectorIn;
	}
	return self;
}

- (void) dealloc
{
	[url release];
	
	[super dealloc];
}

- (void)main
{
	ALBuffer* buffer = [[OALAudioSupport sharedInstance] bufferFromUrl:url mono:mono];
	[target performSelectorOnMainThread:selector withObject:buffer waitUntilDone:NO];
}

@end



#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private methods for OALAudioSupport. 
 */
@interface OALAudioSupport (Private)

/** (INTERNAL USE) Get an AudioSession property.
 *
 * @param property The property to get.
 * @return The property's value.
 */
- (UInt32) getIntProperty:(AudioSessionPropertyID) property;

/** (INTERNAL USE) Get an AudioSession property.
 *
 * @param property The property to get.
 * @return The property's value.
 */
- (Float32) getFloatProperty:(AudioSessionPropertyID) property;

/** (INTERNAL USE) Get an AudioSession property.
 *
 * @param property The property to get.
 * @return The property's value.
 */
- (NSString*) getStringProperty:(AudioSessionPropertyID) property;

/** (INTERNAL USE) Set an AudioSession property.
 *
 * @param property The property to set.
 * @param value The value to set this property to.
 */
- (void) setIntProperty:(AudioSessionPropertyID) property value:(UInt32) value;

/** (INTERNAL USE) Set the Audio Session category and properties based on current settings.
 */
- (void) setAudioMode;

/** (INTERNAL USE) Update settings to be compatible with the current audio session category.
 */
- (void) updateFromAudioSessionCategory;

/** (INTERNAL USE) Update the audio session category to be compatible with the current settings.
 */
- (void) updateFromFlags;

@end

#pragma mark -
#pragma mark OALAudioSupport

@implementation OALAudioSupport

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALAudioSupport);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);
		operationQueue = [[NSOperationQueue alloc] init];
		[(AVAudioSession*)[AVAudioSession sharedInstance] setDelegate:self];

		// Set up defaults
		handleInterruptions = YES;
		audioSessionDelegate = nil;
		allowIpod = YES;
		ipodDucking = NO;
		useHardwareIfAvailable = YES;
		honorSilentSwitch = YES;
		[self updateFromFlags];

		suspendLock = [[SuspendLock lockWithTarget:self
									  lockSelector:@selector(onSuspend)
									unlockSelector:@selector(onUnsuspend)] retain];
		
		// Activate the audio session.
		self.audioSessionActive = YES;
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	self.audioSessionActive = NO;

	[operationQueue release];
	[audioSessionCategory release];
	[suspendLock release];

	[super dealloc];
}


#pragma mark Properties

- (NSString*) audioSessionCategory
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return audioSessionCategory;
	}
}

- (void) setAudioSessionCategory:(NSString*) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[audioSessionCategory autorelease];
		audioSessionCategory = [value retain];
		[self updateFromAudioSessionCategory];
		[self setAudioMode];
	}	
}

- (bool) allowIpod
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return allowIpod;
	}
}

- (void) setAllowIpod:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		allowIpod = value;
		[self updateFromFlags];
		[self setAudioMode];
	}
}

- (bool) ipodDucking
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return ipodDucking;
	}
}

- (void) setIpodDucking:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		ipodDucking = value;
		[self updateFromFlags];
		[self setAudioMode];
	}
}

- (bool) useHardwareIfAvailable
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return useHardwareIfAvailable;
	}
}

- (void) setUseHardwareIfAvailable:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		useHardwareIfAvailable = value;
		[self updateFromFlags];
		[self setAudioMode];
	}
}

@synthesize handleInterruptions;
@synthesize audioSessionDelegate;

- (bool) honorSilentSwitch
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return honorSilentSwitch;
	}
}

- (void) setHonorSilentSwitch:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		honorSilentSwitch = value;
		[self updateFromFlags];
		[self setAudioMode];
	}
}

- (bool) ipodPlaying
{
	return 0 != [self getIntProperty:kAudioSessionProperty_OtherAudioIsPlaying];
}

- (NSString*) audioRoute
{
#if !TARGET_IPHONE_SIMULATOR
	return [self getStringProperty:kAudioSessionProperty_AudioRoute];
#else /* !TARGET_IPHONE_SIMULATOR */
	return nil;
#endif /* !TARGET_IPHONE_SIMULATOR */
}

- (float) hardwareVolume
{
	return [self getFloatProperty:kAudioSessionProperty_CurrentHardwareOutputVolume];
}

- (bool) hardwareMuted
{
	return [[self audioRoute] isEqualToString:@""];
}


#pragma mark Buffers

- (ALBuffer*) bufferFromFile:(NSString*) filePath
{
	return [self bufferFromFile:filePath mono:NO];
}

- (ALBuffer*) bufferFromFile:(NSString*) filePath mono:(bool) mono
{
	return [self bufferFromUrl:[OALAudioSupport urlForPath:filePath] mono:mono];
}

- (ALBuffer*) bufferFromUrl:(NSURL*) url
{
	return [self bufferFromUrl:url mono:NO];
}

- (ALBuffer*) bufferFromUrl:(NSURL*) url mono:(bool) mono
{
	if(nil == url)
	{
		OAL_LOG_ERROR(@"Cannot open NULL file / url");
		return nil;
	}
	
	OAL_LOG_DEBUG(@"Load buffer from %@", url);
	
	// Holds any errors that occur.
	OSStatus error;
	
	// Handle to the file we'll be reading from.
	ExtAudioFileRef fileHandle = nil;
	
	// This will hold the data we'll be passing to the OpenAL buffer.
	void* streamData = nil;
	
	// This is the buffer object we'll be returning to the caller.
	ALBuffer* alBuffer = nil;
	
	// Local variables that will be used later on.
	// They need to be pre-declared so that the compiler doesn't throw a hissy fit
	// over the goto statements if you compile as Objective-C++.
	SInt64 numFrames;
	UInt32 numFramesSize = sizeof(numFrames);
	
	AudioStreamBasicDescription audioStreamDescription;
	UInt32 descriptionSize = sizeof(audioStreamDescription);
	
	UInt32 streamSizeInBytes;
	AudioBufferList bufferList;
	UInt32 numFramesToRead;
	ALenum audioFormat;
	
	
	// Open the file
	if(noErr != (error = ExtAudioFileOpenURL((CFURLRef)url, &fileHandle)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not open url %@", url);
		goto done;
	}
	
	// Find out how many frames there are
	if(noErr != (error = ExtAudioFileGetProperty(fileHandle,
												 kExtAudioFileProperty_FileLengthFrames,
												 &numFramesSize,
												 &numFrames)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not get frame count for url %@", url);
		goto done;
	}
	
	// Get the audio format
	if(noErr != (error = ExtAudioFileGetProperty(fileHandle,
												 kExtAudioFileProperty_FileDataFormat,
												 &descriptionSize,
												 &audioStreamDescription)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not get audio format for url %@", url);
		goto done;
	}
	
	// Specify the new audio format (anything not changed remains the same)
	audioStreamDescription.mFormatID = kAudioFormatLinearPCM;
	audioStreamDescription.mFormatFlags = kAudioFormatFlagsNativeEndian |
	kAudioFormatFlagIsSignedInteger |
	kAudioFormatFlagIsPacked;
	audioStreamDescription.mBitsPerChannel = 16;
	
	if(mono)
	{
		audioStreamDescription.mChannelsPerFrame = 1;
	}
	
	if(audioStreamDescription.mChannelsPerFrame > 2)
	{
		// Don't allow more than 2 channels (stereo)
		OAL_LOG_WARNING(@"Audio stream for url %@ contains %d channels. Capping at 2.", url, audioStreamDescription.mChannelsPerFrame);
		audioStreamDescription.mChannelsPerFrame = 2;
	}
	audioStreamDescription.mBytesPerFrame = audioStreamDescription.mChannelsPerFrame * audioStreamDescription.mBitsPerChannel / 8;
	audioStreamDescription.mFramesPerPacket = 1;
	audioStreamDescription.mBytesPerPacket = audioStreamDescription.mBytesPerFrame * audioStreamDescription.mFramesPerPacket;
	
	// Set the new audio format
	if(noErr != (error = ExtAudioFileSetProperty(fileHandle,
												 kExtAudioFileProperty_ClientDataFormat,
												 descriptionSize,
												 &audioStreamDescription)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not set new audio format for url %@", url);
		goto done;
	}
	
	// Allocate some memory to hold the data
	streamSizeInBytes = audioStreamDescription.mBytesPerFrame * (SInt32)numFrames;
	streamData = malloc(streamSizeInBytes);
	if(nil == streamData)
	{
		OAL_LOG_ERROR(@"Could not allocate %d bytes for url %@", streamSizeInBytes, url);
		goto done;
	}
	
	// Read the data from the file to our buffer, in the new format
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mNumberChannels = audioStreamDescription.mChannelsPerFrame;
	bufferList.mBuffers[0].mDataByteSize = streamSizeInBytes;
	bufferList.mBuffers[0].mData = streamData;
	
	numFramesToRead = (UInt32)numFrames;
	if(noErr != (error = ExtAudioFileRead(fileHandle, &numFramesToRead, &bufferList)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not read audio data from url %@", url);
		goto done;
	}
	
	if(1 == audioStreamDescription.mChannelsPerFrame)
	{
		if(8 == audioStreamDescription.mBitsPerChannel)
		{
			audioFormat = AL_FORMAT_MONO8;
		}
		else
		{
			audioFormat = AL_FORMAT_MONO16;
		}
	}
	else
	{
		if(8 == audioStreamDescription.mBitsPerChannel)
		{
			audioFormat = AL_FORMAT_STEREO8;
		}
		else
		{
			audioFormat = AL_FORMAT_STEREO16;
		}
	}
	
	alBuffer = [ALBuffer bufferWithName:[url absoluteString]
								   data:streamData
								   size:streamSizeInBytes
								 format:audioFormat
							  frequency:(ALsizei)audioStreamDescription.mSampleRate];
	// ALBuffer is maintaining this memory now.  Make sure we don't free() it.
	streamData = nil;
	
done:
	if(nil != fileHandle)
	{
		REPORT_EXTAUDIO_CALL(ExtAudioFileDispose(fileHandle), @"Error closing audio file");
	}
	if(nil != streamData)
	{
		free(streamData);
	}
	return alBuffer;
}

- (NSString*) bufferAsyncFromFile:(NSString*) filePath
						   target:(id) target
						 selector:(SEL) selector
{
	return [self bufferAsyncFromFile:filePath
								mono:NO
							  target:target
							selector:selector];
}

- (NSString*) bufferAsyncFromFile:(NSString*) filePath
							 mono:(bool) mono
						   target:(id) target
						 selector:(SEL) selector
{
	return [self bufferAsyncFromUrl:[OALAudioSupport urlForPath:filePath]
							   mono:mono
							 target:target
						   selector:selector];
}

- (NSString*) bufferAsyncFromUrl:(NSURL*) url
						  target:(id) target
						selector:(SEL) selector
{
	return [self bufferAsyncFromUrl:url
							   mono:NO
							 target:target
						   selector:selector];
}

- (NSString*) bufferAsyncFromUrl:(NSURL*) url
							mono:(bool) mono
						  target:(id) target
						selector:(SEL) selector
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[operationQueue addOperation:
		 [OAL_AsyncALBufferLoadOperation operationWithUrl:url
													 mono:mono
												   target:target
												 selector:selector]];
	}
	return [url absoluteString];
}


#pragma mark Audio Error Utility

+ (void) logAudioSessionError:(OSStatus)errorCode
					 function:(const char*) function
				  description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		if(nil == audioSessionErrorCodes){
			audioSessionErrorCodes = [[NSDictionary dictionaryWithObjectsAndKeys:
									   @"Session not initialized", [NSNumber numberWithInt:kAudioSessionNotInitialized],
									   @"Session already initialized", [NSNumber numberWithInt:kAudioSessionAlreadyInitialized],
									   @"Sesion initialization error", [NSNumber numberWithInt:kAudioSessionInitializationError],
									   @"Unsupported session property", [NSNumber numberWithInt:kAudioSessionUnsupportedPropertyError],
									   @"Bad session property size", [NSNumber numberWithInt:kAudioSessionBadPropertySizeError],
									   @"Session is not active", [NSNumber numberWithInt:kAudioSessionNotActiveError], 
#if 0 // Documented but not implemented on iOS
									   @"Hardware not available for session", [NSNumber numberWithInt:kAudioSessionNoHardwareError],
#endif
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
									   @"No session category set", [NSNumber numberWithInt:kAudioSessionNoCategorySet],
									   @"Incompatible session category",[NSNumber numberWithInt:kAudioSessionIncompatibleCategory],
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
									   nil] retain];			
		}
		
		NSString* errorString = [audioSessionErrorCodes objectForKey:[NSNumber numberWithInt:errorCode]];
		if(nil == errorString)
		{
			errorString = @"Unknown session error";
		}
		va_list args;
		va_start(args, description);
		description = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
		va_end(args);
		OAL_LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
	}
}

+ (void) logExtAudioError:(OSStatus)errorCode
				 function:(const char*) function
			  description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		if(nil == extAudioErrorCodes){
			extAudioErrorCodes = [[NSDictionary dictionaryWithObjectsAndKeys:
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
								   @"Write function interrupted - last buffer written", [NSNumber numberWithInt:kExtAudioFileError_CodecUnavailableInputConsumed],
								   @"Write function interrupted - last buffer not written", [NSNumber numberWithInt:kExtAudioFileError_CodecUnavailableInputNotConsumed],
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
								   @"Invalid property", [NSNumber numberWithInt:kExtAudioFileError_InvalidProperty],
								   @"Invalid property size", [NSNumber numberWithInt:kExtAudioFileError_InvalidPropertySize],
								   @"Non-PCM client format", [NSNumber numberWithInt:kExtAudioFileError_NonPCMClientFormat],
								   @"Wrong number of channels for format", [NSNumber numberWithInt:kExtAudioFileError_InvalidChannelMap],
								   @"Invalid operation order", [NSNumber numberWithInt:kExtAudioFileError_InvalidOperationOrder],
								   @"Invalid data format", [NSNumber numberWithInt:kExtAudioFileError_InvalidDataFormat],
								   @"Max packet size unknown", [NSNumber numberWithInt:kExtAudioFileError_MaxPacketSizeUnknown],
								   @"Seek offset out of bounds", [NSNumber numberWithInt:kExtAudioFileError_InvalidSeek],
								   @"Async write too large", [NSNumber numberWithInt:kExtAudioFileError_AsyncWriteTooLarge],
								   @"Async write could not be completed in time", [NSNumber numberWithInt:kExtAudioFileError_AsyncWriteBufferOverflow],
								   nil] retain];			
		}
		
		NSString* errorString = [extAudioErrorCodes objectForKey:[NSNumber numberWithInt:errorCode]];
		if(nil == errorString)
		{
			errorString = @"Unknown ext audio error";
		}
		va_list args;
		va_start(args, description);
		description = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
		va_end(args);
		OAL_LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
	}
}

#pragma mark Utility

+ (NSURL*) urlForPath:(NSString*) path
{
	if(nil == path)
	{
		return nil;
	}
	NSString* fullPath = path;
	if([fullPath characterAtIndex:0] != '/')
	{
		fullPath = [[NSBundle mainBundle] pathForResource:[[path pathComponents] lastObject] ofType:nil];
		if(nil == fullPath)
		{
			OAL_LOG_ERROR(@"Could not find full path of file %@", path);
			return nil;
		}
	}
	
	return [NSURL fileURLWithPath:fullPath];
}


#pragma mark Internal Use

- (UInt32) getIntProperty:(AudioSessionPropertyID) property
{
	UInt32 value = 0;
	UInt32 size = sizeof(value);
	OSStatus result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		result = AudioSessionGetProperty(property, &size, &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get int property %08x", property);
	return value;
}

- (Float32) getFloatProperty:(AudioSessionPropertyID) property
{
	Float32 value = 0;
	UInt32 size = sizeof(value);
	OSStatus result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		result = AudioSessionGetProperty(property, &size, &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get float property %08x", property);
	return value;
}

- (NSString*) getStringProperty:(AudioSessionPropertyID) property
{
	CFStringRef value;
	UInt32 size = sizeof(value);
	OSStatus result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		result = AudioSessionGetProperty(property, &size, &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get string property %08x", property);
	if(noErr == result)
	{
		[(NSString*)value autorelease];
		return (NSString*)value;
	}
	return nil;
}

- (void) setIntProperty:(AudioSessionPropertyID) property value:(UInt32) value
{
	OSStatus result;
	OPTIONALLY_SYNCHRONIZED(self)
	{
		result = AudioSessionSetProperty(property, sizeof(value), &value);
	}
	REPORT_AUDIOSESSION_CALL(result, @"Failed to get int property %08x", property);
}

- (void) setAudioCategory:(NSString*) audioCategory
{
	NSError* error;
	if(![[AVAudioSession sharedInstance] setCategory:audioCategory error:&error])
	{
		OAL_LOG_ERROR(@"Failed to set audio category: %@", error);
	}
}

- (void) updateFromAudioSessionCategory
{
	if([AVAudioSessionCategoryAmbient isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = YES;
		allowIpod = YES;
	}
	else if([AVAudioSessionCategorySoloAmbient isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = YES;
		allowIpod = NO;
	}
	else if([AVAudioSessionCategoryPlayback isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = NO;
	}
	else if([AVAudioSessionCategoryRecord isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = NO;
		allowIpod = NO;
		ipodDucking = NO;
	}
	else if([AVAudioSessionCategoryPlayAndRecord isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = NO;
		allowIpod = NO;
		ipodDucking = NO;
	}
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_1
	else if([AVAudioSessionCategoryAudioProcessing isEqualToString:audioSessionCategory])
	{
		honorSilentSwitch = NO;
		allowIpod = NO;
		ipodDucking = NO;
	}
#endif /* __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_1 */
	else
	{
		OAL_LOG_WARNING(@"%@: Unrecognized audio session category", audioSessionCategory);
	}

}

- (void) updateFromFlags
{
	[audioSessionCategory autorelease];
	if(honorSilentSwitch)
	{
		if(allowIpod)
		{
			audioSessionCategory = [AVAudioSessionCategoryAmbient retain];
		}
		else
		{
			audioSessionCategory = [AVAudioSessionCategorySoloAmbient retain];
		}
	}
	else
	{
		audioSessionCategory = [AVAudioSessionCategoryPlayback retain];
	}
}

- (void) setAudioMode
{
	// Simulator doesn't support setting the audio session category.
#if !TARGET_IPHONE_SIMULATOR
	
	NSString* actualCategory = audioSessionCategory;
	
	// Mixing uses software decoding and mixes with other apps.
	bool mixing = allowIpod;

	// Ducking causes other app audio to lower in volume while this session is active.
	bool ducking = ipodDucking;
	
	// If the hardware is available and we want it, take it.
	if(mixing && useHardwareIfAvailable && !self.ipodPlaying)
	{
		mixing = NO;
	}

	// Handle special case where useHardwareIfAvailable caused us to take the hardware.
	if(!mixing && [AVAudioSessionCategoryAmbient isEqualToString:audioSessionCategory])
	{
		actualCategory = AVAudioSessionCategorySoloAmbient;
	}

	[self setAudioCategory:actualCategory];

	if(!mixing)
	{
		// Setting OtherMixableAudioShouldDuck clears MixWithOthers.
		[self setIntProperty:kAudioSessionProperty_OtherMixableAudioShouldDuck value:ducking];
	}

	if(!ducking)
	{
		// Setting MixWithOthers clears OtherMixableAudioShouldDuck.
		[self setIntProperty:kAudioSessionProperty_OverrideCategoryMixWithOthers value:mixing];
	}
	
#endif /* !TARGET_IPHONE_SIMULATOR */
}

- (bool) audioSessionActive
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		return audioSessionActive;
	}
}

/** Work around for iOS4 bug that causes the session to not activate on the first few attempts
 * in certain situations.
 */ 
- (void) activateAudioSession
{
	NSError* error;
	for(int try = 1; try <= kMaxSessionActivationRetries; try++)
	{
		if([[AVAudioSession sharedInstance] setActive:YES error:&error])
		{
			audioSessionActive = YES;
			return;
		}
		OAL_LOG_ERROR(@"Could not activate audio session after %d tries: %@", try, error);
		[NSThread sleepForTimeInterval:0.2];
	}
	OAL_LOG_ERROR(@"Failed to activate the audio session");
}

- (void) setAudioSessionActive:(bool) value
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(value != audioSessionActive)
		{
			if(value)
			{
				OAL_LOG_DEBUG(@"Activate audio session");
				[self setAudioMode];
				[self activateAudioSession];
			}
			else
			{
				OAL_LOG_DEBUG(@"Deactivate audio session");
				NSError* error;
				if(![[AVAudioSession sharedInstance] setActive:NO error:&error])
				{
					OAL_LOG_ERROR(@"Could not deactivate audio session: %@", error);
				}
				else
				{
					audioSessionActive = NO;
				}
				
			}
		}
	}
}

/** Called by SuspendLock to suspend this object.
 */
- (void) onSuspend
{
	audioSessionWasActive = self.audioSessionActive;
	self.audioSessionActive = NO;
}

/** Called by SuspendLock to unsuspend this object.
 */
- (void) onUnsuspend
{
	if(audioSessionWasActive)
	{
		self.audioSessionActive = YES;
	}
}

- (bool) suspended
{
	// No need to synchronize since SuspendLock does that already.
	return suspendLock.suspendLock;
}

- (void) setSuspended:(bool) value
{
	// Ensure setting/resetting occurs in opposing order
	if(value)
	{
		[OpenALManager sharedInstance].suspended = value;
		[OALAudioTracks sharedInstance].suspended = value;
	}

	// No need to synchronize since SuspendLock does that already.
	suspendLock.suspendLock = value;

	// Ensure setting/resetting occurs in opposing order
	if(!value)
	{
		[OpenALManager sharedInstance].suspended = value;
		[OALAudioTracks sharedInstance].suspended = value;
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
		[OpenALManager sharedInstance].interrupted = value;
		[OALAudioTracks sharedInstance].interrupted = value;
	}

	// No need to synchronize since SuspendLock does that already.
	suspendLock.interruptLock = value;

	// Ensure setting/resetting occurs in opposing order
	if(!value)
	{
		[OpenALManager sharedInstance].interrupted = value;
		[OALAudioTracks sharedInstance].interrupted = value;
	}
}


// AVAudioSessionDelegate
- (void) beginInterruption
{
	OAL_LOG_DEBUG(@"Received interrupt from system.");
	@synchronized(self)
	{
		if(handleInterruptions)
		{
			self.interrupted = YES;
		}
		
		if([audioSessionDelegate respondsToSelector:@selector(beginInterruption)])
		{
			[audioSessionDelegate beginInterruption];
		}
	}
}

- (void) endInterruption
{
	OAL_LOG_DEBUG(@"Received end interrupt from system.");
	@synchronized(self)
	{
		if(handleInterruptions)
		{
			self.interrupted = NO;
		}
		
		if([audioSessionDelegate respondsToSelector:@selector(endInterruption)])
		{
			[audioSessionDelegate endInterruption];
		}
	}
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
	OAL_LOG_DEBUG(@"Received end interrupt with flags 0x%08x from system.", flags);
	@synchronized(self)
	{
		if(handleInterruptions)
		{
			self.interrupted = NO;
		}
		
		if([audioSessionDelegate respondsToSelector:@selector(endInterruptionWithFlags:)])
		{
			[audioSessionDelegate endInterruptionWithFlags:flags];
		}
		else if([audioSessionDelegate respondsToSelector:@selector(endInterruption)])
		{
			[audioSessionDelegate endInterruption];
		}
	}
}

- (void) forceEndInterruption:(bool) informDelegate
{
	@synchronized(self)
	{
		self.interrupted = NO;
		
		if(informDelegate && [audioSessionDelegate respondsToSelector:@selector(endInterruption)])
		{
			[audioSessionDelegate endInterruption];
		}
	}
}

- (void)inputIsAvailableChanged:(BOOL)isInputAvailable
{
	if([audioSessionDelegate respondsToSelector:@selector(inputIsAvailableChanged:)])
	{
		[audioSessionDelegate inputIsAvailableChanged:isInputAvailable];
	}
}


@end
