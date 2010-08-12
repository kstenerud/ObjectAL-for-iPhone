//
//  IphoneAudioSupport.m
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

#import "IphoneAudioSupport.h"
#import "ObjectALMacros.h"
#import <AudioToolbox/AudioToolbox.h>
#import "BackgroundAudio.h"


#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for loading audio files asynchronously.
 */
@interface AsyncLoadOperation : NSOperation
{
	/** The URL containing the sound data. */
	NSURL* url;
	/** The target to inform when loading is complete. */
	id target;
	/** The selector to call when loading is complete. */
	SEL selector;
}

/** (INTERNAL USE) Create an asynchronous load operation.
 *
 * @param target the target to inform when loading is complete.
 * @param selector the selector to call when loading is complete.
 * @param url the URLcontaining the sound data.
 * @return A new load operation.
 */
+ (id) operationWithTarget:(id) target selector:(SEL) selector url:(NSURL*) url;

/** (INTERNAL USE) Initialize an asynchronous load operation.
 *
 * @param target the target to inform when loading is complete.
 * @param selector the selector to call when loading is complete.
 * @param url the URLcontaining the sound data.
 * @return The initialized load operation.
 */
- (id) initWithTarget:(id) target selector:(SEL) selector url:(NSURL*) url;

@end


@implementation AsyncLoadOperation

+ (id) operationWithTarget:(id) target selector:(SEL) selector url:(NSURL*) url
{
	return [[[self alloc] initWithTarget:target selector:selector url:url] autorelease];
}

- (id) initWithTarget:(id) targetIn selector:(SEL) selectorIn url:(NSURL*) urlIn
{
	if(nil != (self = [super init]))
	{
		target = targetIn;
		selector = selectorIn;
		url = [urlIn retain];
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
	ALBuffer* buffer = [[IphoneAudioSupport sharedInstance] bufferFromUrl:url];
	[target performSelectorOnMainThread:selector withObject:buffer waitUntilDone:NO];
}

@end

#pragma mark -
#pragma mark Private Methods

/**
 * (INTERNAL USE) Private methods for IphoneAudioSupport. 
 */
@interface IphoneAudioSupport (Private)

/** (INTERNAL USE) Called when an interrupt begins.
 */
- (void) onInterruptBegin;

/** (INTERNAL USE) Called when an interrupt ends.
 */
- (void) onInterruptEnd;

/** (INTERNAL USE) System callback for interrupts.
 */
static void interruptListenerCallback(void* inUserData, UInt32 interruptionState);

@end

#pragma mark -
#pragma mark IphoneAudioSupport

@implementation IphoneAudioSupport

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(IphoneAudioSupport);

- (id) init
{
	if(nil != (self = [super init]))
	{
		audioSessionErrorCodes = [[NSDictionary dictionaryWithObjectsAndKeys:
								   @"Session not initialized", [NSNumber numberWithInt:kAudioSessionNotInitialized],
								   @"Session already initialized", [NSNumber numberWithInt:kAudioSessionAlreadyInitialized],
								   @"Sesion initialization error", [NSNumber numberWithInt:kAudioSessionInitializationError],
								   @"Unsupported session property", [NSNumber numberWithInt:kAudioSessionUnsupportedPropertyError],
								   @"Bad session property size", [NSNumber numberWithInt:kAudioSessionBadPropertySizeError],
								   @"Session is not active", [NSNumber numberWithInt:kAudioSessionNotActiveError], 
#if 0 // Documented but not implemented on iPhone
								   @"Hardware not available for session", [NSNumber numberWithInt:kAudioSessionNoHardwareError],
#endif
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
								   @"No session category set", [NSNumber numberWithInt:kAudioSessionNoCategorySet],
								   @"Incompatible session category",[NSNumber numberWithInt:kAudioSessionIncompatibleCategory],
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
								  nil] retain];

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
		operationQueue = [[NSOperationQueue alloc] init];
		REPORT_AUDIOSESSION_CALL(AudioSessionInitialize(NULL, NULL, interruptListenerCallback, self), @"Failed to initialize audio session");
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[operationQueue release];
	[audioSessionErrorCodes release];
	[extAudioErrorCodes release];
	[super dealloc];
}


#pragma mark Properties

@synthesize handleInterruptions;


#pragma mark Buffers

- (ALBuffer*) bufferFromFile:(NSString*) filePath
{
	return [self bufferFromUrl:[self urlForPath:filePath]];
}

- (ALBuffer*) bufferFromUrl:(NSURL*) url
{
	if(nil == url)
	{
		LOG_ERROR(@"Cannot open NULL file / url");
		return nil;
	}

	OSStatus error;
	ExtAudioFileRef fileHandle = nil;
	void* streamData = nil;
	ALBuffer* alBuffer = nil;

	// Open the file
	if(noErr != (error = ExtAudioFileOpenURL((CFURLRef)url, &fileHandle)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not open url %@", url);
		goto done;
	}
	
	// Find out how many frames there are
	SInt64 numFrames;
	UInt32 numFramesSize = sizeof(numFrames);
	if(noErr != (error = ExtAudioFileGetProperty(fileHandle,
												 kExtAudioFileProperty_FileLengthFrames,
												 &numFramesSize,
												 &numFrames)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not get frame count for url %@", url);
		goto done;
	}
	
	// Get the audio format
	AudioStreamBasicDescription audioStreamDescription;
	UInt32 descriptionSize = sizeof(audioStreamDescription);
	
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
	if(audioStreamDescription.mChannelsPerFrame > 2)
	{
		// Don't allow more than 2 channels (stereo)
		LOG_WARNING(@"Audio stream for url %@ contains %d channels. Capping at 2.", url, audioStreamDescription.mChannelsPerFrame);
		audioStreamDescription.mChannelsPerFrame = 2;
	}
	// Convert to 8 or 16 bit as necessary
	if(audioStreamDescription.mBitsPerChannel < 8)
	{
		audioStreamDescription.mBitsPerChannel = 8;
	}
	else if(audioStreamDescription.mBitsPerChannel > 8)
	{
		audioStreamDescription.mBitsPerChannel = 16;
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
	UInt32 numBytes = audioStreamDescription.mBytesPerFrame * numFrames;
	streamData = malloc(numBytes);
	if(nil == streamData)
	{
		LOG_ERROR(@"Could not allocate %d bytes for url %@", numBytes, url);
		goto done;
	}
	
	// Read the data from the file to our buffer, in the new format
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mNumberChannels = audioStreamDescription.mChannelsPerFrame;
	bufferList.mBuffers[0].mDataByteSize = numBytes;
	bufferList.mBuffers[0].mData = streamData;
	
	UInt32 framesToRead = (UInt32) numFrames;
	if(noErr != (error = ExtAudioFileRead(fileHandle, &framesToRead, &bufferList)))
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not read audio data from url %@", url);
		goto done;
	}
	
	ALenum format;
	if(1 == audioStreamDescription.mChannelsPerFrame)
	{
		if(8 == audioStreamDescription.mBitsPerChannel)
		{
			format = AL_FORMAT_MONO8;
		}
		else
		{
			format = AL_FORMAT_MONO16;
		}
	}
	else
	{
		if(8 == audioStreamDescription.mBitsPerChannel)
		{
			format = AL_FORMAT_STEREO8;
		}
		else
		{
			format = AL_FORMAT_STEREO16;
		}
	}

	alBuffer = [ALBuffer bufferWithName:[url absoluteString]
								   data:streamData
								   size:numBytes
								 format:format
							  frequency:audioStreamDescription.mSampleRate];
	// ALBuffer is maintaining this memory now.  Make sure we don't free() it.
	streamData = nil;
	
done:
	if(nil != fileHandle)
	{
		ExtAudioFileDispose(fileHandle);
	}
	if(nil != streamData)
	{
		free(streamData);
	}
	return alBuffer;
}

- (NSString*) bufferAsyncFromFile:(NSString*) filePath target:(id) target selector:(SEL) selector
{
	return [self bufferAsyncFromUrl:[self urlForPath:filePath] target:target selector:selector];
}

- (NSString*) bufferAsyncFromUrl:(NSURL*) url target:(id) target selector:(SEL) selector
{
	SYNCHRONIZED_OP(self)
	{
		[operationQueue addOperation:[AsyncLoadOperation operationWithTarget:target selector:selector url:url]];
	}
	return [url absoluteString];
}


#pragma mark Internal Utility

- (void) logAudioSessionError:(OSStatus)errorCode function:(const char*) function description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		NSString* errorString = [audioSessionErrorCodes objectForKey:[NSNumber numberWithInt:errorCode]];
		if(nil == errorString)
		{
			errorString = @"Unknown session error";
		}
		va_list args;
		va_start(args, description);
		description = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
		va_end(args);
		LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
	}
}

- (void) logExtAudioError:(OSStatus)errorCode function:(const char*) function description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		NSString* errorString = [extAudioErrorCodes objectForKey:[NSNumber numberWithInt:errorCode]];
		if(nil == errorString)
		{
			errorString = @"Unknown ext audio error";
		}
		va_list args;
		va_start(args, description);
		description = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
		va_end(args);
		LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
	}
}


#pragma mark Utility

- (NSURL*) urlForPath:(NSString*) path
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
			LOG_ERROR(@"Could not find full path of file %@", path);
			return nil;
		}
	}
	
	return [NSURL fileURLWithPath:fullPath];
}


#pragma mark Internal Use

- (bool) suspended
{
	SYNCHRONIZED_OP(self)
	{
		return [ObjectAL sharedInstance].suspended && [BackgroundAudio sharedInstance].suspended;
	}
}

- (void) setSuspended:(bool) suspended
{
	SYNCHRONIZED_OP(self)
	{
		[ObjectAL sharedInstance].suspended = suspended;
		[BackgroundAudio sharedInstance].suspended = suspended;
		
		if(!suspended)
		{
			suspendedByInterrupt = NO;
		}
	}
}

- (void) onInterruptBegin
{
	SYNCHRONIZED_OP(self)
	{
		if(handleInterruptions && !self.suspended)
		{
			suspendedByInterrupt = YES;
			self.suspended = YES;
		}
	}
}

- (void) onInterruptEnd
{
	SYNCHRONIZED_OP(self)
	{
		if(handleInterruptions && suspendedByInterrupt)
		{
			self.suspended = NO;
		}
	}
}

static void interruptListenerCallback(void* inUserData, UInt32 interruptionState)
{
	IphoneAudioSupport* handler = (IphoneAudioSupport*) inUserData;
	switch(interruptionState)
	{
		case kAudioSessionBeginInterruption:
			[handler onInterruptBegin];
			break;
		case kAudioSessionEndInterruption:
			[handler onInterruptEnd];
			break;
	}
}

@end
