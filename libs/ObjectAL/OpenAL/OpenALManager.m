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
#import "NSMutableArray+WeakReferences.h"
#import "ObjectALMacros.h"
#import "ALWrapper.h"
#import "ALDevice.h"
#import "OALAudioSession.h"
#import "OALAudioFile.h"


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
	ALBuffer* buffer = [OALAudioFile bufferFromUrl:url reduceToMono:reduceToMono];
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

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

/** (INTERNAL USE) Called by SuspendHandler.
 */
- (void) setSuspended:(bool) value;

@end


#pragma mark -
#pragma mark OpenALManager

@implementation OpenALManager



#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OpenALManager);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);

		suspendHandler = [[OALSuspendHandler alloc] initWithTarget:self selector:@selector(setSuspended:)];
		
		devices = [NSMutableArray newMutableArrayUsingWeakReferencesWithCapacity:5];

		operationQueue = [[NSOperationQueue alloc] init];

		[[OALAudioSession sharedInstance] addSuspendListener:self];
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	[[OALAudioSession sharedInstance] removeSuspendListener:self];

	[self closeOSResources];

	[operationQueue release];
	[suspendHandler release];
	[devices release];
	
	[super dealloc];
}

- (void) closeOSResources
{
	// Not directly holding any OS resources.
}

- (void) close
{
	OPTIONALLY_SYNCHRONIZED(self)
	{
		if(nil != devices)
		{
			[devices makeObjectsPerformSelector:@selector(close)];
			[devices release];
			devices = nil;
			
			[self closeOSResources];
		}
	}
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
	OAL_LOG_DEBUG(@"Load buffer from %@", url);

	return [OALAudioFile bufferFromUrl:url reduceToMono:reduceToMono];
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
