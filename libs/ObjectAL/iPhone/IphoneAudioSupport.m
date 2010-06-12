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

/** (INTERNAL USE) Check for an error condition and report if necessary.
 *
 * @param errorCode the return code from an audio operation.
 */
- (void) checkForError:(OSStatus) errorCode;

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
		operationQueue = [[NSOperationQueue alloc] init];
		[self checkForError:AudioSessionInitialize(NULL, NULL, interruptListenerCallback, self)];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[operationQueue release];
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
		return nil;
	}

	OSStatus error;
	ExtAudioFileRef fileHandle = nil;
	void* streamData = nil;
	ALBuffer* alBuffer = nil;

	// Open the file
	if(noErr != (error = ExtAudioFileOpenURL((CFURLRef)url, &fileHandle)))
	{
		NSLog(@"Error: IphoneAudioSupport: Could not open url %@ (error code %d)", url, error);
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
		NSLog(@"Error: IphoneAudioSupport: Could not get frame count for url %@ (error code %d)", url, error);
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
		NSLog(@"Error: IphoneAudioSupport: Could not get audio format for url %@ (error code %d)", url, error);
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
		NSLog(@"Warning: IphoneAudioSupport: Audio stream for url %@ contains %d channels.  Capping at 2.", url, audioStreamDescription.mChannelsPerFrame);
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
		NSLog(@"Error: IphoneAudioSupport: Could not set new audio format for url %@ (error code %d)", url, error);
		goto done;
	}
	
	// Allocate some memory to hold the data
	UInt32 numBytes = audioStreamDescription.mBytesPerFrame * numFrames;
	streamData = malloc(numBytes);
	if(nil == streamData)
	{
		NSLog(@"Error: IphoneAudioSupport: Could not allocate %d bytes for url %@", numBytes, url);
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
		NSLog(@"Error: IphoneAudioSupport: Could not read audio data from url %@ (error code %d)", url, error);
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
	[operationQueue addOperation:[AsyncLoadOperation operationWithTarget:target selector:selector url:url]];
	return [url absoluteString];
}


#pragma mark Internal Utility

- (void) checkForError:(OSStatus) errorCode
{
	switch(errorCode)
	{
		case kAudioSessionNoError:
			break;
		case kAudioSessionNotInitialized:
			NSLog(@"Error: IphoneAudioSupport: Session not initialized (error code %x)", errorCode);
			break;
		case kAudioSessionAlreadyInitialized:
			NSLog(@"Error: IphoneAudioSupport: Session already initialized (error code %x)", errorCode);
			break;
		case kAudioSessionInitializationError:
			NSLog(@"Error: IphoneAudioSupport: Sesion initialization error (error code %x)", errorCode);
			break;
		case kAudioSessionUnsupportedPropertyError:
			NSLog(@"Error: IphoneAudioSupport: Unsupported session property (error code %x)", errorCode);
			break;
		case kAudioSessionBadPropertySizeError:
			NSLog(@"Error: IphoneAudioSupport: Bad session property size (error code %x)", errorCode);
			break;
		case kAudioSessionNotActiveError:
			NSLog(@"Error: IphoneAudioSupport: Session is not active (error code %x)", errorCode);
			break;
#if 0 // Documented but not implemented on iPhone
		case kAudioSessionNoHardwareError:
			NSLog(@"Error: IphoneAudioSupport: Hardware not available for session (error code %x)", errorCode);
			break;
#endif
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
		case kAudioSessionNoCategorySet:
			NSLog(@"Error: IphoneAudioSupport: No session category set (error code %x)", errorCode);
			break;
		case kAudioSessionIncompatibleCategory:
			NSLog(@"Error: IphoneAudioSupport: Incompatible session category (error code %x)", errorCode);
			break;
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
		default:
			NSLog(@"Error: IphoneAudioSupport: Unknown session error (error code %x)", errorCode);
	}
}


#pragma mark Utility

- (NSURL*) urlForPath:(NSString*) path
{
	if([path characterAtIndex:0] != '/')
	{
		NSString* fullPath = [[NSBundle mainBundle] pathForResource:[[path pathComponents] lastObject] ofType:nil];
		if(nil == fullPath)
		{
			NSLog(@"Error: IphoneAudioSupport: Could not find file %@", path);
			return nil;
		}
		path = fullPath;
	}
	
	return [NSURL fileURLWithPath:path];
}


#pragma mark Internal Use

- (bool) suspended
{
	return [ObjectAL sharedInstance].suspended && [BackgroundAudio sharedInstance].suspended;
}

- (void) setSuspended:(bool) suspended
{
	@synchronized(self)
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
	if(handleInterruptions && !self.suspended)
	{
		suspendedByInterrupt = YES;
		self.suspended = YES;
	}
}

- (void) onInterruptEnd
{
	if(handleInterruptions && suspendedByInterrupt)
	{
		self.suspended = NO;
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
