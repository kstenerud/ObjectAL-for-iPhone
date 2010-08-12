//
//  ObjectALConfig.h
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



/** When this option is enabled, all critical ObjectAL operations will be wrapped in
 * synchronized blocks.
 * Turning this off can improve performance a bit if your application makes heavy
 * use of audio calls, but you'll be on your own for ensuring two threads don't
 * access the same part of the audio library at the same time.
 */
#define OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS 1


/** When this option is enabled, ObjectAL will output log entries for any errors that occur.
 * In general, turning this off won't help performance since the log code only gets called
 * when an error occurs.  There can be a slight improvement, however, since it won't even
 * check return codes in many cases.
 */
#define OBJECTAL_CFG_LOG_ERRORS 1


/** The CLANG/LLVM 1.5 compiler that ships with XCode 3.2.3 fails when compiling a method
 * which takes a struct and passes that struct or one of its components to a C function
 * from within a @synchronized(self) context when compiling for the Device in Debug
 * configuration (Apple issue #8303765).
 * If this option is enabled, all synchronization will be disabled for methods which fall
 * under this category. <br>
 * Note: This only takes effect if the CLANG compiler is used (__clang__ == 1)
 */
#define OBJECTAL_CLANG_LLVM_BUG_WORKAROUND 1


/** When this option is enabled, ObjectAL will invoke special code when playback ends for
 * any reason on the simulator.  This is to counter a bug where the simulator would mute
 * OpenAL playback when AVAudioPlayer playback ends.
 * With XCode 3.2.3, this bug seems to be fixed.
 */
#define OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND 0
