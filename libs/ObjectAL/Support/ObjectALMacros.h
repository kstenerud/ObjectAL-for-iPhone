//
//  ObjectALMacros.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-02.
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

#import "ObjectALConfig.h"

#pragma mark -
#pragma mark Configuration


#pragma mark -
#pragma mark Synchronization

#if OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS

#define OPTIONALLY_SYNCHRONIZED(A) @synchronized(A)

#else

#define OPTIONALLY_SYNCHRONIZED(A)

#endif /* OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS */


#pragma mark -
#pragma mark LLVM Bug Workaround

#if OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND && __clang__

#define OPTIONALLY_SYNCHRONIZED_STRUCT_OP(A)

#else

#define OPTIONALLY_SYNCHRONIZED_STRUCT_OP(A) OPTIONALLY_SYNCHRONIZED(A)

#endif /* OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND */


#pragma mark -
#pragma mark MPMusicPlayerController bug workaround

#if OBJECTAL_CFG_INTERRUPT_BUG_WORKAROUND

#define OBJECTAL_INTERRUPT_BUG_WORKAROUND() [context ensureContextIsCurrent]
#define OBJECTAL_CONTEXT_INTERRUPT_BUG_WORKAROUND() [self ensureContextIsCurrent]

#else /* OBJECTAL_CFG_INTERRUPT_BUG_WORKAROUND */

#define OBJECTAL_INTERRUPT_BUG_WORKAROUND()
#define OBJECTAL_CONTEXT_INTERRUPT_BUG_WORKAROUND()

#endif /* OBJECTAL_CFG_INTERRUPT_BUG_WORKAROUND */


#pragma mark -
#pragma mark Logging


#pragma mark -
#pragma mark General Logging

/** Base log call.  This is called by other logging macros.
 *
 * @param FMT_STRING The format string to use.  Must contain %s for the context and %@ for the message.
 * @param CONTEXT The calling context, as a C string (typically __PRETTY_FUNCTION__).
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#define OAL_LOG_BASE(FMT_STRING, CONTEXT, FMT, ...)	\
	NSLog(FMT_STRING, (CONTEXT), [NSString stringWithFormat:(FMT), ##__VA_ARGS__]);

/** Write an "Info" log entry.
 *
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#if OBJECTAL_CFG_LOG_LEVEL > 2
#define OAL_LOG_INFO(FMT, ...) OAL_LOG_BASE(@"Info: %s: %@", __PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)
#else /* OBJECTAL_CFG_LOG_LEVEL */
#define OAL_LOG_INFO(FMT, ...)
#endif /* OBJECTAL_CFG_LOG_LEVEL */

/** Write a "Warning" log entry.
 *
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#if OBJECTAL_CFG_LOG_LEVEL > 1
#define OAL_LOG_WARNING(FMT, ...) OAL_LOG_BASE(@"Warning: %s: %@", __PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)
#else /* OBJECTAL_CFG_LOG_LEVEL */
#define OAL_LOG_WARNING(FMT, ...)
#endif /* OBJECTAL_CFG_LOG_LEVEL */

/** Write an "Error" log entry.
 *
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#if OBJECTAL_CFG_LOG_LEVEL > 0
#define OAL_LOG_ERROR(FMT, ...) OAL_LOG_BASE(@"Error: %s: %@", __PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)
#else /* OBJECTAL_CFG_LOG_LEVEL */
#define OAL_LOG_ERROR(FMT, ...)
#endif /* OBJECTAL_CFG_LOG_LEVEL */

/** Write an "Error" log entry with context.
 *
 * @param CONTEXT The calling context, as a C string (typically __PRETTY_FUNCTION__).
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#if OBJECTAL_CFG_LOG_LEVEL > 0
#define OAL_LOG_ERROR_CONTEXT(CONTEXT, FMT, ...) OAL_LOG_BASE(@"Error: %s: %@", CONTEXT, FMT, ##__VA_ARGS__)
#else /* OBJECTAL_CFG_LOG_LEVEL */
#define OAL_LOG_ERROR_CONTEXT(FMT, ...)
#endif /* OBJECTAL_CFG_LOG_LEVEL */

#pragma mark -
#pragma mark Special Purpose Logging

#if OBJECTAL_CFG_LOG_LEVEL > 0

/** Report on the specified AudioSession error code, logging an error if the code does not indicate success.
 *
 * @param ERROR_CODE The error code.
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#define REPORT_AUDIOSESSION_CALL(ERROR_CODE, FMT, ...) \
if(noErr != (ERROR_CODE)) \
{ \
	[OALAudioSupport logAudioSessionError:(ERROR_CODE) function:__PRETTY_FUNCTION__ description:(FMT), ##__VA_ARGS__]; \
}

/** Report on the specified ExtAudio error code, logging an error if the code does not indicate success.
 *
 * @param ERROR_CODE The error code.
 * @param FMT Message with NSLog() style formatting.
 * @param ... Arguments
 */
#define REPORT_EXTAUDIO_CALL(ERROR_CODE, FMT, ...) \
if(noErr != (ERROR_CODE)) \
{ \
	[OALAudioSupport logExtAudioError:(ERROR_CODE) function:__PRETTY_FUNCTION__ description:(FMT), ##__VA_ARGS__]; \
}

#else /* OBJECTAL_CFG_LOG_LEVEL */

#define REPORT_AUDIOSESSION_CALL(ERROR_CODE, FMT, ...)
#define REPORT_EXTAUDIO_CALL(ERROR_CODE, FMT, ...)

#endif /* OBJECTAL_CFG_LOG_LEVEL */
