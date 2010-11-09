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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//


/* Compile-time configuration for ObjectAL.
 *
 * The defines in this file provide broad guidelines for how ObjectAL will behave
 * in your application.  They can either be set here, or you can set them as user
 * defines in your build configuration.
 */


/** Enables support for methods that take blocks as arguments.
 * Blocks are only supported in iOS 4.0+, so enabling this will make your project
 * incompatible with earlier operating systems (a 3.x system will crash the moment it
 * encounters a class that supports blocks).
 *
 * Recommended setting: 0 if you want to support iOS prior to 4.0, 1 if you don't care.
 */
#ifndef OBJECTAL_CFG_USE_BLOCKS
#define OBJECTAL_CFG_USE_BLOCKS 0
#endif


/** Determines how ObjectAL's actions are implemented.
 * If this is set to 1, ObjectAL's actions will inherit from cocos2d CCIntervalAction,
 * and will use cocos2d's CCActionManager rather than OALActionManager. <br>
 *
 * Recommended setting: 1 if you use Cocos2d exclusively, 0 if you use UIKit.
 */
#ifndef OBJECTAL_CFG_USE_COCOS2D_ACTIONS
#define OBJECTAL_CFG_USE_COCOS2D_ACTIONS 0
#endif


/** Sets the interval in seconds between steps when performing actions with OALAction
 * subclasses. Lower values offer better accuracy, but take up more processing time
 * because they fire more often. <br>
 *
 * Generally, you want at least 4-5 steps in an audio operation, so for durations
 * of 0.2 and above, an interval of 1/30 is fine.  For anything lower, you'll want a
 * smaller interval. <br>
 *
 * Note: The NSTimer documentation states that a timer will typically have a resolution
 * of around 0.05 to 0.1, though in practice smaller values seem to work fine. <br>
 *
 * Recommended setting: 1.0/30
 */
#ifndef kActionStepInterval
#define kActionStepInterval (1.0/30)
#endif


/** When this option is enabled, all critical ObjectAL operations will be wrapped in
 * synchronized blocks. <br>
 *
 * Turning this off can improve performance a bit if your application makes heavy
 * use of audio calls, but you'll be on your own for ensuring two threads don't
 * access the same part of the audio library at the same time. <br>
 *
 * Recommended setting: 1
 */
#ifndef OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS
#define OBJECTAL_CFG_SYNCHRONIZED_OPERATIONS 1
#endif

/** When this option is greater than zero, ObjectAL will output log entries for that correspond to the LEVEL.
 * LEVEL = 0 // No output
 * LEVEL = 1 // Errors only
 * LEVEL = 2 // Errors & Warnings
 * LEVEL = 3 // Errors, Warnings & Info
 * In general, setting this to zero won't help performance since the log code only gets called
 * when an error occurs.  There can be a slight improvement, however, since it won't even
 * check return codes in many cases. <br>
 *
 * Recommended setting: 1
 */
#ifndef OBJECTAL_CFG_LOG_LEVEL
#define OBJECTAL_CFG_LOG_LEVEL 1
#endif


/** There are various cases with certain iOS versions where the audio session will receive an
 * "interrupt begin" event, but no corresponding "interrupt end" event, causing the OpenAL context
 * to remain disabled. <br>
 * If this option is enabled, it will add extra processing to all ALSource, ALListener,
 * and ALContext operations to ensure that the context is set up properly. <br>
 *
 * This bug is known to surface in iOS 4.0 when you start playback using MPMusicPlayerController,
 * and when locking/unlocking the device in iOS 4.2 GM.  The lock/unlock bug is already handled
 * elsewhere, so the only time you'd actually need to have this set is if you're using
 * MPMusicPlayerController and expect the app to be run on an iOS 4.0 (rather than 4.1 or 4.2) device.
 *
 * Recommended setting: 1 if you're using MPMusicPlayerController, 0 otherwise.
 */
#ifndef OBJECTAL_CFG_INTERRUPT_BUG_WORKAROUND
#define OBJECTAL_CFG_INTERRUPT_BUG_WORKAROUND 1
#endif


/** The CLANG/LLVM 1.5 compiler that ships with XCode 3.2.3 fails when compiling a method
 * which takes a struct and passes that struct or one of its components to a C function
 * from within a @synchronized(self) context when compiling for the Device in Debug
 * configuration (Apple issue #8303765). <br>
 *
 * If this option is enabled, all synchronization will be disabled for methods which fall
 * under this category. <br>
 *
 * Note: This only takes effect if the CLANG compiler is used (__clang__ == 1) <br>
 *
 * Recommended setting: 1
 */
#ifndef OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND
#define OBJECTAL_CFG_CLANG_LLVM_BUG_WORKAROUND 1
#endif


/** When this option is enabled, ObjectAL will invoke special code when playback ends for
 * any reason on the simulator.  This is to counter a bug where the simulator would mute
 * OpenAL playback when AVAudioPlayer playback ends. <br>
 *
 * Note: With XCode 3.2.3, this bug seems to be fixed. <br>
 *
 * Recommended setting: 0 for XCode 3.2.3, 1 for earlier versions.
 */
#ifndef OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND
#define OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND 0
#endif
