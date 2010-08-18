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
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ObjectALConfig.h"

#pragma mark -
#pragma mark Configuration


#pragma mark OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS

#if OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS

#define OPTIONALLY_SYNCHRONIZED(A) @synchronized(A)

#else

#define OPTIONALLY_SYNCHRONIZED(A)

#endif /* OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS */


#pragma mark -
#pragma mark OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND

#if OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND && __clang__

#define OPTIONALLY_SYNCHRONIZED_STRUCT_OP(A)

#else

#define OPTIONALLY_SYNCHRONIZED_STRUCT_OP(A) OPTIONALLY_SYNCHRONIZED(A)

#endif /* OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND */


#pragma mark -
#pragma mark Logging

#if OBJECTAL_CFG_LOG_ERRORS

/** Write a warning log entry with the specified calling context.
 *
 * @param CONTEXT The calling context, typically __PRETTY_FUNCTION__ (C-string, not NSString!)
 * @param FMT Printf-style format describing the warning condition
 * @param ... Arguments
 */
#define LOG_WARNING_CONTEXT(CONTEXT, FMT, ...) \
{ \
	NSString* error_log_strXX = [NSString stringWithFormat:(FMT), ##__VA_ARGS__]; \
	NSLog(@"Warning: %s: %@", (CONTEXT), error_log_strXX); \
}

/** Write an error log entry with the specified calling context.
 *
 * @param CONTEXT The calling context, typically __PRETTY_FUNCTION__ (C-string, not NSString!)
 * @param FMT Printf-style format describing the error condition
 * @param ... Arguments
 */
#define LOG_ERROR_CONTEXT(CONTEXT, FMT, ...) \
{ \
	NSString* error_log_strXX = [NSString stringWithFormat:(FMT), ##__VA_ARGS__]; \
	NSLog(@"Error: %s: %@", (CONTEXT), error_log_strXX); \
}

#else /* OBJECTAL_CFG_LOG_ERRORS */

#define LOG_WARNING_CONTEXT(CONTEXT, FMT, ...)
#define LOG_ERROR_CONTEXT(CONTEXT, FMT, ...)

#endif /* OBJECTAL_CFG_LOG_ERRORS */


/** Write a warning log entry with __PRETTY_FUNCTION__ as the calling context.
 *
 * @param FMT Printf-style format describing the warning condition
 * @param ... Arguments
 */
#define LOG_WARNING(FMT, ...) LOG_WARNING_CONTEXT(__PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)

/** Write an error log entry with __PRETTY_FUNCTION__ as the calling context.
 *
 * @param FMT Printf-style format describing the error condition
 * @param ... Arguments
 */
#define LOG_ERROR(FMT, ...) LOG_ERROR_CONTEXT(__PRETTY_FUNCTION__, FMT, ##__VA_ARGS__)


#if OBJECTAL_CFG_LOG_ERRORS

/** Report on the specified AudioSession error code, logging an error if the code does not indicate success.
 *
 * @param ERROR_CODE The error code.
 * @param FMT Printf-style format describing the error condition
 * @param ... Arguments
 */
#define REPORT_AUDIOSESSION_CALL(ERROR_CODE, FMT, ...) \
if(noErr != (ERROR_CODE)) \
{ \
	[self logAudioSessionError:(ERROR_CODE) function:__PRETTY_FUNCTION__ description:(FMT), ##__VA_ARGS__]; \
}

/** Report on the specified ExtAudio error code, logging an error if the code does not indicate success.
 *
 * @param ERROR_CODE The error code.
 * @param FMT Printf-style format describing the error condition
 * @param ... Arguments
 */
#define REPORT_EXTAUDIO_CALL(ERROR_CODE, FMT, ...) \
if(noErr != (ERROR_CODE)) \
{ \
	[self logExtAudioError:(ERROR_CODE) function:__PRETTY_FUNCTION__ description:(FMT), ##__VA_ARGS__]; \
}

#else /* OBJECTAL_CFG_LOG_ERRORS */

#define REPORT_AUDIOSESSION_CALL(ERROR_CODE, FMT, ...)
#define REPORT_EXTAUDIO_CALL(ERROR_CODE, FMT, ...)

#endif /* OBJECTAL_CFG_LOG_ERRORS */
