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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "OpenALManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "NSMutableArray+WeakReferences.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "OALTools.h"
#import "OALAudioSession.h"


#pragma mark -
#pragma mark Asynchronous Operations

/**
 * (INTERNAL USE) NSOperation for loading audio files asynchronously.
 */
@interface OAL_AsyncALBufferLoadOperation: NSOperation
{
	/** The URL of the sound file to play */
	NSURL* url;
	/** If true, reduce the sample to mono */
	bool reduceToMono;
	/** The target to inform when the operation completes */
	id target;
	/** The selector to call when the operation completes */
	SEL selector;
}

/** (INTERNAL USE) Create a new Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
+ (id) operationWithUrl:(NSURL*) url
		   reduceToMono:(bool) reduceToMono
				 target:(id) target
			   selector:(SEL) selector;

/** (INTERNAL USE) Initialize an Asynchronous Operation.
 *
 * @param url the URL containing the sound file.
 * @param reduceToMono If true, reduce the sample to mono
 *        (stereo samples don't support panning or positional audio).
 * @param target the target to inform when the operation completes.
 * @param selector the selector to call when the operation completes.
 */ 
- (id) initWithUrl:(NSURL*) url
	  reduceToMono:(bool) reduceToMono
			target:(id) target
		  selector:(SEL) selector;

@end

@implementation OAL_AsyncALBufferLoadOperation

+ (id) operationWithUrl:(NSURL*) url
		   reduceToMono:(bool) reduceToMono
				 target:(id) target
			   selector:(SEL) selector
{
	return [[[self alloc] initWithUrl:url
						 reduceToMono:reduceToMono
							   target:target
							 selector:selector] autorelease];
}

- (id) initWithUrl:(NSURL*) urlIn
	  reduceToMono:(bool) reduceToMonoIn
			target:(id) targetIn
		  selector:(SEL) selectorIn
{
	if(nil != (self = [super init]))
	{
		url = [urlIn retain];
		reduceToMono = reduceToMonoIn;
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
	ALBuffer* buffer = [[OpenALManager sharedInstance] bufferFromUrl:url reduceToMono:reduceToMono];
	[target performSelectorOnMainThread:selector withObject:buffer waitUntilDone:NO];
}

@end


#pragma mark -
#pragma mark Private Methods

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OpenALManager);

/**
 * (INTERNAL USE) Private methods for OpenALManager.
 */
@interface OpenALManager (Private)

/** (INTERNAL USE) Called by SuspendHandler.
 */
- (void) setSuspended:(bool) value;

@end


#pragma mark -
#pragma mark OpenALManager

@implementation OpenALManager

/** Dictionary mapping ExtAudio error codes to human readable descriptions.
 * Key: NSNumber, Value: NSString
 */
static NSDictionary* extAudioErrorCodes = nil;


#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OpenALManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);

		suspendHandler = [[OALSuspendHandler handlerWithTarget:self selector:@selector(setSuspended:)] retain];
		
		devices = [[NSMutableArray mutableArrayUsingWeakReferencesWithCapacity:5] retain];

		operationQueue = [[NSOperationQueue alloc] init];

		[[OALAudioSession sharedInstance] addSuspendListener:self];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	[[OALAudioSession sharedInstance] removeSuspendListener:self];
	[operationQueue release];
	self.currentContext = nil;
	[devices release];
	[suspendHandler release];
	
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
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		currentContext = context;
		[ALWrapper makeContextCurrent:currentContext.context deviceReference:currentContext.device.device];
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
		if(self.suspended)
		{
			OAL_LOG_DEBUG(@"%@: Called mutator on suspended object", self);
			return;
		}
		
		[ALWrapper setMixerOutputDataRate:frequency];
	}
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

- (void) setSuspended:(bool) value
{
	if(value)
	{
		[ALWrapper makeContextCurrent:nil];
	}
	else
	{
		[ALWrapper makeContextCurrent:currentContext.context
					  deviceReference:currentContext.device.device];
	}
}


#pragma mark Buffers

- (ALBuffer*) bufferFromFile:(NSString*) filePath
{
	return [self bufferFromFile:filePath reduceToMono:NO];
}

- (ALBuffer*) bufferFromFile:(NSString*) filePath reduceToMono:(bool) reduceToMono
{
	return [self bufferFromUrl:[OALTools urlForPath:filePath] reduceToMono:reduceToMono];
}

- (ALBuffer*) bufferFromUrl:(NSURL*) url
{
	return [self bufferFromUrl:url reduceToMono:NO];
}

- (ALBuffer*) bufferFromUrl:(NSURL*) url reduceToMono:(bool) reduceToMono
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
	// Force to 16 bit since iOS doesn't seem to like 8 bit.
	audioStreamDescription.mBitsPerChannel = 16;
	
	if(reduceToMono)
	{
		audioStreamDescription.mChannelsPerFrame = 1;
	}
	else if(audioStreamDescription.mChannelsPerFrame > 2)
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
	@synchronized(self)
	{
		// ExtAudioFileRead is not thread-safe
		error = ExtAudioFileRead(fileHandle, &numFramesToRead, &bufferList);
	}
	if(noErr != error)
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

- (ALBuffer*) bufferFromFile:(ExtAudioFileRef) fileHandle
					  frames:(UInt32) numFrames
			channelsPerFrame:(UInt32) channelsPerFrame
			   bytesPerFrame:(UInt32) bytesPerFrame
				  sampleRate:(ALsizei) sampleRate
				 audioFormat:(ALenum) audioFormat
					   named:(NSString*) name
{
	OSStatus error;
	UInt32 numFramesRead;
	ALBuffer* alBuffer = nil;
	
	// Allocate some memory to hold the data
	UInt32 streamSizeInBytes = bytesPerFrame * numFrames;
	void* streamData = malloc(streamSizeInBytes);
	if(nil == streamData)
	{
		OAL_LOG_ERROR(@"Could not allocate %d bytes for audio buffer %@", streamSizeInBytes, name);
		goto done;
	}
	
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mNumberChannels = channelsPerFrame;
	bufferList.mBuffers[0].mDataByteSize = streamSizeInBytes;
	bufferList.mBuffers[0].mData = streamData;
	
	numFramesRead = numFrames;
	@synchronized(self)
	{
		// ExtAudioFileRead is not thread-safe
		error = ExtAudioFileRead(fileHandle, &numFramesRead, &bufferList);
	}
	if(noErr != error)
	{
		REPORT_EXTAUDIO_CALL(error, @"Could not read audio data for audio buffer %@", name);
		goto done;
	}
	
	alBuffer = [ALBuffer bufferWithName:name
								   data:streamData
								   size:streamSizeInBytes
								 format:audioFormat
							  frequency:sampleRate];
	// ALBuffer is maintaining this memory now.  Make sure we don't free() it.
	streamData = nil;
	
done:
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
						reduceToMono:NO
							  target:target
							selector:selector];
}

- (NSString*) bufferAsyncFromFile:(NSString*) filePath
					 reduceToMono:(bool) reduceToMono
						   target:(id) target
						 selector:(SEL) selector
{
	return [self bufferAsyncFromUrl:[OALTools urlForPath:filePath]
					   reduceToMono:reduceToMono
							 target:target
						   selector:selector];
}

- (NSString*) bufferAsyncFromUrl:(NSURL*) url
						  target:(id) target
						selector:(SEL) selector
{
	return [self bufferAsyncFromUrl:url
					   reduceToMono:NO
							 target:target
						   selector:selector];
}

- (NSString*) bufferAsyncFromUrl:(NSURL*) url
					reduceToMono:(bool) reduceToMono
						  target:(id) target
						selector:(SEL) selector
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		[operationQueue addOperation:
		 [OAL_AsyncALBufferLoadOperation operationWithUrl:url
											 reduceToMono:reduceToMono
												   target:target
												 selector:selector]];
	}
	return [url absoluteString];
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

#pragma mark Internal Use

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
