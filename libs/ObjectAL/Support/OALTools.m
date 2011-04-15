//
//  OALTools.m
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

#import "OALTools.h"
#import "ObjectALMacros.h"
#import "OALNotifications.h"
#import <AudioToolbox/AudioToolbox.h>


@implementation OALTools

+ (NSURL*) urlForPath:(NSString*) path
{
	if(nil == path)
	{
		return nil;
	}
	NSString* fullPath = path;
	if([fullPath characterAtIndex:0] != '/')
	{
		fullPath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
		if(nil == fullPath)
		{
			OAL_LOG_ERROR(@"Could not find full path of file %@", path);
			return nil;
		}
	}
	
	return [NSURL fileURLWithPath:fullPath];
}

+ (void) notifyExtAudioError:(OSStatus)errorCode
				 function:(const char*) function
			  description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		NSString* errorString;
		
		switch(errorCode)
		{
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
			case kExtAudioFileError_CodecUnavailableInputConsumed:
				errorString = @"Write function interrupted - last buffer written";
				break;
			case kExtAudioFileError_CodecUnavailableInputNotConsumed:
				errorString = @"Write function interrupted - last buffer not written";
				break;
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
			case kExtAudioFileError_InvalidProperty:
				errorString = @"Invalid property";
				break;
			case kExtAudioFileError_InvalidPropertySize:
				errorString = @"Invalid property size";
				break;
			case kExtAudioFileError_NonPCMClientFormat:
				errorString = @"Non-PCM client format";
				break;
			case kExtAudioFileError_InvalidChannelMap:
				errorString = @"Wrong number of channels for format";
				break;
			case kExtAudioFileError_InvalidOperationOrder:
				errorString = @"Invalid operation order";
				break;
			case kExtAudioFileError_InvalidDataFormat:
				errorString = @"Invalid data format";
				break;
			case kExtAudioFileError_MaxPacketSizeUnknown:
				errorString = @"Max packet size unknown";
				break;
			case kExtAudioFileError_InvalidSeek:
				errorString = @"Seek offset out of bounds";
				break;
			case kExtAudioFileError_AsyncWriteTooLarge:
				errorString = @"Async write too large";
				break;
			case kExtAudioFileError_AsyncWriteBufferOverflow:
				errorString = @"Async write could not be completed in time";
				break;
			default:
				errorString = @"Unknown ext audio error";
		}

		va_list args;
		va_start(args, description);
		description = [[NSString alloc] initWithFormat:description arguments:args];
		va_end(args);
		OAL_LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
		[description release];
	}
}

+ (void) notifyAudioSessionError:(OSStatus)errorCode
					 function:(const char*) function
				  description:(NSString*) description, ...
{
	if(noErr != errorCode)
	{
		NSString* errorString;
		bool postNotification = NO;
		
		switch(errorCode)
		{
			case kAudioSessionNotInitialized:
				errorString = @"Audio session not initialized";
				postNotification = YES;
				break;
			case kAudioSessionAlreadyInitialized:
				errorString = @"Audio session already initialized";
				postNotification = YES;
				break;
			case kAudioSessionInitializationError:
				errorString = @"Audio sesion initialization error";
				postNotification = YES;
				break;
			case kAudioSessionUnsupportedPropertyError:
				errorString = @"Unsupported audio session property";
				break;
			case kAudioSessionBadPropertySizeError:
				errorString = @"Bad audio session property size";
				break;
			case kAudioSessionNotActiveError:
				errorString = @"Audio session is not active";
				postNotification = YES;
				break;
#if 0 // Documented but not implemented on iOS
			case kAudioSessionNoHardwareError:
				errorString = @"Hardware not available for audio session";
				postNotification = YES;
				break;
#endif
#ifdef __IPHONE_3_1
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1
			case kAudioSessionNoCategorySet:
				errorString = @"No audio session category set";
				postNotification = YES;
				break;
			case kAudioSessionIncompatibleCategory:
				errorString = @"Incompatible audio session category";
				postNotification = YES;
				break;
#endif /* __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_1 */
#endif /* __IPHONE_3_1 */
			default:
				errorString = @"Unknown audio session error";
				postNotification = YES;
		}

#if OBJECTAL_CFG_LOG_LEVEL > 0
		va_list args;
		va_start(args, description);
		description = [[NSString alloc] initWithFormat:description arguments:args];
		va_end(args);
		OAL_LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08x: %@)", description, errorCode, errorString);
		[description release];
#endif /* OBJECTAL_CFG_LOG_LEVEL > 0 */
		
		if(postNotification)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:OALAudioErrorNotification object:self];
		}
	}
}

@end
