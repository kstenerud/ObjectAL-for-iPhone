//
//  ObjectAL.h
//  ObjectAL
//
//  Created by Karl Stenerud on 15/12/09.
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

// Actions
#import "OALAction.h"
#import "OALAudioActions.h"
#import "OALUtilityActions.h"
#import "OALActionManager.h"
#import "OALFunction.h"

// AudioTrack
#import "OALAudioTrack.h"
#import "OALAudioTracks.h"
#import "OALAudioTrackNotifications.h"

// OpenAL
#import "ALTypes.h"
#import "ALBuffer.h"
#import "ALCaptureDevice.h"
#import "ALContext.h"
#import "ALDevice.h"
#import "ALListener.h"
#import "ALSource.h"
#import "ALWrapper.h"
#import "ALChannelSource.h"
#import "ALSoundSourcePool.h"
#import "OpenALManager.h"

// Other
#import "OALAudioSupport.h"
#import "OALSimpleAudio.h"



/** \mainpage ObjectAL for iPhone
 
 Version 2.0 <br> <br>
 
 Copyright 2009-2010 Karl Stenerud <br><br>
 
 Released under the <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache License v2.0</a>
 
 <br> <br>
 \section contents_sec Contents
 - \ref intro_sec
 - \ref objectal_and_openal_sec
 - \ref audio_formats_sec
 - \ref add_objectal_sec (also, installing the documentation into XCode)
 - \ref configuration_sec
 - \ref use_iossimpleaudio_sec
 - \ref use_objectal_sec
 - \ref other_examples_sec
 - \ref simulator_issues_sec
 
 
 <br> <br>
 \section intro_sec Introduction
 
 \htmlonly
 <strong>ObjectAL for iPhone</strong> is designed to be a simpler, more intuitive interface to
 OpenAL and AVAudioPlayer.
 There are four main parts to <strong>ObjectAL for iPhone</strong>:<br/><br/>
 \endhtmlonly
 
 \image html ObjectAL-Overview1.png

 - <a class="el" href="index.html#objectal_and_openal_sec">ObjectAL</a>
   gives you full access to the OpenAL system without the hassle of the C API.
   All OpenAL operations can be performed using first class objects and properties, without needing
   to muddle around with arrays of data, maintain IDs, or pass around pointers to basic types.

 - OALAudioTrack provides a simpler interface to AVAudioPlayer, allowing you to play, stop,
   pause, fade, and mute background music tracks.
 
 - OALAudioSupport provides support functionality for audio in iOS devices, including automatic
   interrupt handling and audio data loading routines. <br>
   As well, it provides an easy way to configure how the audio session will handle iPod-style music
   playing and the silent switch.
 
 - OALSimpleAudio layers on top of the other three, providing an even simpler interface for
   playing background music and sound effects.
  
 
 <br> <br>
 \section objectal_and_openal_sec ObjectAL and OpenAL
 
 <strong>ObjectAL</strong> follows the same basic principles as the
 <a href="http://connect.creativelabs.com/openal">
 OpenAL API (http://connect.creativelabs.com/openal) </a>.
 
 \image html ObjectAL-Overview2.png
 
 - OpenALManager provides some overall controls that affect everything, and manages the current
   context.
 
 - ALDevice represents a physical audio device. <br>
   Each device can have one or more contexts (ALContext) created on it, and can have multiple
   buffers (ALBuffer) associated with it.

 - ALContext controls the overall sound environment, such as distance model, doppler effect, and
   speed of sound. <br>
   Each context has one listener (ALListener), and can have multiple sources (ALSource) opened on
   it (up to a maximum of 32 overall on iPhone).
 
 - ALListener represents the listener of sounds originating on its context (one listener per
   context). It has position, orientation, and velocity.
 
 - ALSource is a sound emitting source that plays sound data from an ALBuffer.  It has position,
   direction, velocity, as well as other properties which determine how the sound is emitted.
 
 - ALChannelSource allows you to reserve a certain number of sources for special purposes.
 
 - ALBuffer is simply a container for sound data.  Only linear PCM is supported directly, but
   OALAudioSupport load methods, and OALSimpleAudio effect preload and play methods, will
   automatically convert any formats that don't require hardware decoding (though conversion
   results in a longer loading time).
 
 Further information regarding the more advanced features of OpenAL (such as distance models)
 are available via the
 <a href="http://connect.creativelabs.com/openal/Documentation/Forms/AllItems.aspx">
 OpenAL Documentation at Creative Labs</a>. <br>
 In particular, read up on the various property values for sources and listeners (such as Doppler
 Shift) in the <strong>OpenAL Programmer's Guide</strong>, and distance models in section 3 of the
 <strong>OpenAL Specification</strong>. <br>
 Also be sure to read the
 <a href="http://developer.apple.com/library/ios/#technotes/tn2008/tn2199.html">
 OpenAL FAQ from Apple</a>.
 
 
 <br> <br>
 \section audio_formats_sec Audio Formats
 According to the
 <a href="http://developer.apple.com/library/ios/#technotes/tn2008/tn2199.html">
 OpenAL FAQ from Apple</a>:
 - To use OpenAL for playback, your application typically reads audio data from disk using Extended
   Audio File Services. In this process you convert the on-disk format, as needed, into one of the
   OpenAL playback formats (OALAudioSupport and OALSimpleAudio do this for you).

 - The on-disk audio format that your application reads must be PCM (uncompressed) or a compressed
   format that does not use hardware decompression, such as IMA-4.
 
 - The supported playback formats for OpenAL in iPhone OS are identical to those for OpenAL in Mac
   OS X. You can play the following linear PCM variants: mono 8-bit, mono 16-bit, stereo 8-bit, and
   stereo 16-bit.
 
 OALAudioTrack supports all hardware and software decoded formats as
 <a href="http://developer.apple.com/library/ios/#documentation/AudioVideo/Conceptual/MultimediaPG/UsingAudio/UsingAudio.html">
 specified by Apple here</a>.

 
 <br> <br>
 \section add_objectal_sec Adding ObjectAL to your project
 
 \htmlonly
 To add ObjectAL to your project, do the following:

 <ol>
	<li>Copy libs/ObjectAL from this project into your project.  You can simply drag it into the
		"Groups & Files" section in xcode if you like (be sure to select "Copy items into
		destination group's folder"). <br/>
		Alternatively, you can build ObjectAL as a static library (as it's configured to do in the
		ObjectAL demo project).<br/><br/>
	</li>

	<li>Add the following frameworks to your project:
		<ul>
			<li>OpenAL.framework</li>
			<li>AudioToolbox.framework</li>
			<li>AVFoundation.framework</li>
		</ul><br/>
	</li>
 
	<li>Start using ObjectAL!<br/></br/></li>
 </ol>
 <br/>
 <strong>Note:</strong> The demos in this project use
 <a href="http://www.cocos2d-iphone.org">Cocos2d</a>, a very nice 2d game engine.  However,
 ObjectAL doesn't require it.  You can just as easily use ObjectAL in your Cocoa app or anything
 you wish.
 <br/> <br/>
 <strong>Note #2:</strong> You do NOT have to provide a link to the Apache license from within your
 application. Simply including a copy of the license in your project is sufficient.
 \endhtmlonly

 <br>
 \subsection install_dox Installing the ObjectAL Documentation into XCode
 
 \htmlonly
 You can install the ObjectAL documentation into XCode's Developer Documentation system by doing
 the following: 
 \endhtmlonly
 -# Install <a href="http://www.doxygen.org">Doxygen</a>
 -# Ensure that the "DOXYGEN_PATH" user-defined setting in Documentation's build configuration
    matches where Doxygen is installed on your system.
 -# Build the "Doxumentation" target in this project.
 -# Open the developer documentation and type "ObjectAL" into the search box.
 
 
 <br> <br>
 \section configuration_sec Compile-Time Configuration
 
 <strong>ObjectALConfig.h</strong> contains configuration defines that will affect at a high level
 how ObjectAL behaves.  Look inside <strong>ObjectALConfig.h</strong> to see what can be
 configured, and what each configuration value does. <br>
 The recommended values are fine for most users, but Cocos2D users may want to set
 OBJECTAL_USE_COCOS2D_ACTIONS so that the audio actions (such as fade) use the Cocos2D action manager.

 
 <br> <br>
 \section use_iossimpleaudio_sec Using OALSimpleAudio
 
 By far, the easiest component to use is OALSimpleAudio.  You sacrifice some power for
 ease-of-use, but for many projects it is more than sufficient.
 
 Here is a code example:
 
 \code
// OALSimpleAudioSample.h

@interface OALSimpleAudioSample : NSObject
{
	// No objects to keep track of...
}

@end


// OALSimpleAudioSample.m

#import "OALSimpleAudioSample.h"
#import "ObjectAL.h"

#define SHOOT_SOUND @"shoot.caf"
#define EXPLODE_SOUND @"explode.caf"

#define INGAME_MUSIC_FILE @"bg_music.mp3"
#define GAMEOVER_MUSIC_FILE @"gameover_music.mp3"

@implementation OALSimpleAudioSample

- (id) init
{
	if(nil != (self = [super init]))
	{
		// We don't want ipod music to keep playing since
		// we have our own bg music.
		[OALSimpleAudio sharedInstance].allowIpod = NO;
		
		// Mute all audio if the silent switch is turned on.
		[OALSimpleAudio sharedInstance].honorSilentSwitch = YES;
		
		// This loads the sound effects into memory so that
		// there's no delay when we tell it to play them.
		[[OALSimpleAudio sharedInstance] preloadEffect:SHOOT_SOUND];
		[[OALSimpleAudio sharedInstance] preloadEffect:EXPLODE_SOUND];
	}
	return self;
}

- (void) onGameStart
{
	// Play the BG music and loop it.
	[[OALSimpleAudio sharedInstance] playBg:INGAME_MUSIC_FILE loop:YES];
}

- (void) onGamePause
{
	[OALSimpleAudio sharedInstance].paused = YES;
}

- (void) onGameResume
{
	[OALSimpleAudio sharedInstance].paused = NO;
}

- (void) onGameOver
{
	// Could use stopEverything here if you want
	[[OALSimpleAudio sharedInstance] stopAllEffects];
	
	// We only play the game over music through once.
	[[OALSimpleAudio sharedInstance] playBg:GAMEOVER_MUSIC_FILE];
}

- (void) onShipShotABullet
{
	[[OALSimpleAudio sharedInstance] playEffect:SHOOT_SOUND];
}

- (void) onShipGotHit
{
	[[OALSimpleAudio sharedInstance] playEffect:EXPLODE_SOUND];
}

- (void) onQuitToMainMenu
{
	// Stop all music and sound effects.
	[[OALSimpleAudio sharedInstance] stopEverything];	
	
	// Unload all sound effects and bg music so that it doesn't fill
	// memory unnecessarily.
	[[OALSimpleAudio sharedInstance] unloadAllEffects];
}

@end
\endcode
 
 
 <br> <br>
 \section use_objectal_sec Using the OpenAL Objects and OALAudioTrack
 
 The OpenAL objects and OALAudioTrack offer you much more power at the cost
 of complexity.
 Here's the same thing as above, done using ObjectAL and OALAudioTrack directly:
 
 \code
// OpenALAudioTrackSample.h

#import "ObjectAL.h"

@interface OpenALAudioTrackSample : NSObject
{
	// Sound Effects
	ALDevice* device;
	ALContext* context;
	ALChannelSource* channel;
	ALBuffer* shootBuffer;	
	ALBuffer* explosionBuffer;
	
	// Background Music
	OALAudioTrack* musicTrack;
}

@end


// OpenALAudioTrackSample.m

#import "OpenALAudioTrackSample.h"

#define SHOOT_SOUND @"shoot.caf"
#define EXPLODE_SOUND @"explode.caf"

#define INGAME_MUSIC_FILE @"bg_music.mp3"
#define GAMEOVER_MUSIC_FILE @"gameover_music.mp3"

@implementation OpenALAudioTrackSample

- (id) init
{
	if(nil != (self = [super init]))
	{
		// Create the device and context.
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[OpenALManager sharedInstance].currentContext = context;
		
		// Deal with interruptions for me!
		[OALAudioSupport sharedInstance].handleInterruptions = YES;
		
		// We don't want ipod music to keep playing since
		// we have our own bg music.
		[OALAudioSupport sharedInstance].allowIpod = NO;
		
		// Mute all audio if the silent switch is turned on.
		[OALAudioSupport sharedInstance].honorSilentSwitch = YES;
		
		// Take all 32 sources for this channel.
		// (we probably won't use that many but what the heck!)
		channel = [[ALChannelSource channelWithSources:32] retain];
		
		// Preload the buffers so we don't have to load and play them later.
		shootBuffer = [[[OALAudioSupport sharedInstance]
						bufferFromFile:SHOOT_SOUND] retain];
		explosionBuffer = [[[OALAudioSupport sharedInstance]
							bufferFromFile:EXPLODE_SOUND] retain];
		
		// Background music track.
		musicTrack = [[OALAudioTrack track] retain];
	}
	return self;
}

- (void) dealloc
{
	[musicTrack release];
	
	[channel release];
	[shootBuffer release];
	[explosionBuffer release];
	
	// Note: You'll likely only have one device and context open throughout
	// your program, so in a real program you'd be better off making a
	// singleton object that manages the device and context, rather than
	// allocating/deallocating it here.
	// Most of the demos just let OALSimpleAudio manage the device and context
	// for them.
	[context release];
	[device release];
	
	[super dealloc];
}

- (void) onGameStart
{
	// Play the BG music and loop it forever.
	[musicTrack playFile:INGAME_MUSIC_FILE loops:-1];
}

- (void) onGamePause
{
	musicTrack.paused = YES;
	channel.paused = YES;
}

- (void) onGameResume
{
	channel.paused = NO;
	musicTrack.paused = NO;
}

- (void) onGameOver
{
	[channel stop];
	[musicTrack stop];
	
	// We only play the game over music through once.
	[musicTrack playFile:GAMEOVER_MUSIC_FILE];
}

- (void) onShipShotABullet
{
	[channel play:shootBuffer];
}

- (void) onShipGotHit
{
	[channel play:explosionBuffer];
}

- (void) onQuitToMainMenu
{
	// Stop all music and sound effects.
	[channel stop];
	[musicTrack stop];
}

@end
 \endcode
 
 
 
 <br> <br>
 \section other_examples_sec Other Examples
 
 The demo scenes in this distribution have been crafted to demonstrate common uses of this library.
 Try them out and go through the code to see how it's done.  I've done my best to keep the code
 readable. Really!
 
 The current demos are:
 - <strong>SingleSourceDemo</strong>: Demonstrates using a location based source and a listener.
 - <strong>TwoSourceDemo</strong>: Demonstrates using two location based sources and a listener.
 - <strong>VolumePitchPanDemo</strong>: Demonstrates using gain, pitch, and pan controls.
 - <strong>CrossFadeDemo</strong>: Demonstrates crossfading between two sources.
 - <strong>ChannelsDemo</strong>: Demonstrates using audio channels.
 - <strong>FadeDemo</strong>: Demonstrates realtime fading with OALAudioTrack and ALSource.
 - <strong>AudioTrackDemo</strong>: Demonstrates using multiple OALAudioTrack objects.
 - <strong>HardwareDemo</strong>: Demonstrates hardware monitoring features.
 - <strong>PlanetKillerDemo</strong>: Demonstrates using OALSimpleAudio in a game setting.
 
 
 
 <br> <br>
 \section simulator_issues_sec Simulator Issues
 
 As you've likely heard time and time again, the simulator is no substitute for the real thing.
 The simulator is buggy.  It can run faster or slower than a real device.  It fails system calls
 that a real device doesn't.  It shows graphics glitches that a real device doesn't.  Sounds stop
 working, clicks and static, dogs and cats living together, etc, etc.
 When things look wrong, try it on a real device before bugging people.
 
 
 <br>
 \subsection simulator_limitations Simulator Limitations
 
 The simulator does not support setting audio modes, so setting allowIpod or honorSilentSwitch
 in OALAudioSupport will have no effect in the simulator.
 
 
 <br>
 \subsection simulator_errors Error Codes on the Simulator
 
 From time to time, the simulator can get confused, and start spitting out spurious errors.
 When this happens, check on a real device to make sure it's not just a simulator issue.
 Usually quitting and restarting the simulator will fix it, but sometimes you may have to reboot
 your machine as well.
 
 
 <br>
 \subsection simulator_playback Playback Issues
 
 The simulator is notoriously finicky when it comes to audio playback.  Any number of programs
 you've installed on your mac can cause the simulator to stop playing bg music, or effects, or
 both!
 
 Some things to check when sound stops working:
 - Try resetting and restarting the simulator.
 - Try restarting XCode, cleaning, and recompiling your project.
 - Try rebooting your computer.
 - Open "Audio MIDI Setup" (type "midi" into spotlight to find it) and make sure "Built-in Output"
 is set to 44100.0 Hz.
 - Go to System Preferences -> Sound -> Output, and ensure that "Play sound effects through" is set
   to "Internal Speakers"
 - Go to System Preferences -> Sound -> Input, and ensure that it is using internal sound devices.
 - Go to System Preferences -> Sound -> Sound Effects, and ensure "Play user interface sound
   effects" is checked.
 - Some codecs may cause problems with sound playback.  Try removing them.
 - Programs that redirect audio can wreak havoc on the simulator.  Try removing them.
 
 
 <br>
 \subsection simulator_no_sound No OpenAL Sound in Simulator

 <strong>Note:</strong> As of XCode 3.2.3, this problem doesn't seem to be surfacing anymore.
 The workaround code is now disabled by default.  You can re-enable it by setting
 OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND to 1 in ObjectALConfig.h.

 There's a bug in the simulator that causes OpenAL-based sounds to stop playing in certain cases
 when using AVAudioPlayer (OALAudioTrack).  ObjectAL contains code to work around this issue,
 but it's not a 100% fix.
 
 
 <br>
 \subsection simulator_freezing Simulator Freezups
 
 <strong>Note:</strong> As of XCode 3.2.3, this problem doesn't seem to be surfacing anymore.
 The workaround code is now disabled by default.  You can re-enable it by setting
 OBJECTAL_CFG_SIMULATOR_BUG_WORKAROUND to 1 in ObjectALConfig.h.
 
 There's a particularly nasty bug in the simulator's OpenAL and AVAudioPlayer implementation that
 causes the simulator to freeze for 60+ seconds in a very specific case:
 
 If you use OALAudioTrack to play background music, then stop the music,
 then close the current OpenAL context, the simulator will freeze (a real device won't).
 
 This is not really a huge problem, however, since you really should be making a sound manager
 singleton object (what OALSimpleAudio is, basically) to handle the ALDevice and ALContext
 (which will in 99.9% of cases last for the entire duration of your program).
 
 If you absolutely must close the current OpenAL context, start any OALAudioTrack objects playing
 at 0 volume first.
 
 */
