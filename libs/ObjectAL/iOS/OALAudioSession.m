//
//  OALAudioSession.m
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

#import "OALAudioSession.h"
#import "ObjectALMacros.h"
#import <AudioToolbox/AudioToolbox.h>

// TODO: Factor these out
#import "ObjectAL.h"
#import "OALInterruptAPI.h"
//ADD_INTERRUPT_API(OALAudioSession);
ADD_INTERRUPT_API(OpenALManager);
ADD_INTERRUPT_API(OALAudioTracks);


#define kMaxSessionActivationRetries 40

#pragma mark -
#pragma mark Private Methods

SYNTHESIZE_SINGLETON_FOR_CLASS_PROTOTYPE(OALAudioSession);


/**
 * (INTERNAL USE) Private methods for OALAudioSupport. 
 */
@interface OALAudioSession (Private)

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

/** (INTERNAL USE) Called by SuspendLock to suspend this object.
 */
- (void) onSuspend;

/** (INTERNAL USE) Called by SuspendLock to unsuspend this object.
 */
- (void) onUnsuspend;

@end


@implementation OALAudioSession

/** Dictionary mapping audio session error codes to human readable descriptions.
 * Key: NSNumber, Value: NSString
 */
static NSDictionary* audioSessionErrorCodes = nil;

#pragma mark Object Management

SYNTHESIZE_SINGLETON_FOR_CLASS(OALAudioSession);

- (id) init
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);
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

- (void) onSuspend
{
	audioSessionWasActive = self.audioSessionActive;
	self.audioSessionActive = NO;
}

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
