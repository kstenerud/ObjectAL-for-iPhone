//
//  OALTools.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-12-19.
//
//  Copyright (c) 2009 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Attribution is not required, but appreciated :)
//

#import "OALTools.h"
#import "ObjectALMacros.h"
#import "OALNotifications.h"
#import <AudioToolbox/AudioToolbox.h>


@implementation OALTools

static NSBundle* g_defaultBundle;

+ (void) initialize
{
    g_defaultBundle = [NSBundle mainBundle];
}

+ (void) setDefaultBundle:(NSBundle*) bundle
{
    g_defaultBundle = bundle;
}

+ (NSBundle*) defaultBundle
{
    return g_defaultBundle;
}

+ (NSURL*) urlForPath:(NSString*) path
{
    return [self urlForPath:path bundle:g_defaultBundle];
}

+ (NSURL*) urlForPath:(NSString*) path bundle:(NSBundle*) bundle
{
	if(nil == path)
	{
		return nil;
	}
	NSString* fullPath = path;
	if([fullPath characterAtIndex:0] != '/')
	{
		fullPath = [bundle pathForResource:path ofType:nil];
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
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED)
			case kExtAudioFileError_CodecUnavailableInputConsumed:
				errorString = @"Write function interrupted - last buffer written";
				break;
			case kExtAudioFileError_CodecUnavailableInputNotConsumed:
				errorString = @"Write function interrupted - last buffer not written";
				break;
#endif
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
		OAL_LOG_ERROR_CONTEXT(function, @"%@ (error code 0x%08lx: %@)", description, (unsigned long)errorCode, errorString);
	}
}

@end
