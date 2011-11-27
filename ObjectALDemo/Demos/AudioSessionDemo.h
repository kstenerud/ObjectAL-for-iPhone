//
//  AudioSessionDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "cocos2d.h"
#import "LampButton.h"
#import "ObjectAL.h"

/**
 * This is mainly a test scene to try out various combinations of
 * audio session settings.
 *
 * Generally, you should set up the audio session settings ONCE, and then
 * use your program. Changing around settings after playing sounds or using
 * iPod playback can cause problems in certain situations, resulting in
 * no sound being output, error messages (especially in OpenAL), and even
 * crashes. You can try changing around live settings in this demo to see
 * what works and what doesn't, but there's no guarantee of consistency in
 * Apple's already obscure implementation.
 *
 *
 * The buttons are as follows:
 *
 * Session Active: Controls the audio session's state (active or not).
 * Once OpenAL initializes, you can't deactivate the session without first
 * disabling the current OpenAL context.
 *
 * Suspended: Controls suspending the sound system.  This works every time
 * because it first suspends OpenAL and AVAudioPlayer.
 * You need to suspend and resume for some of the audio session settings to
 * take effect.
 *
 * Allow iPod: When enabled, the application will use software decoding
 * (except in a special case where "Use Hardware" is enabled, see below).
 * This allows it to coexist with iPod music playing.
 *
 * iPod Ducking: When enabled, causes any iPod style music to decrease
 * in volume while the audio session is active.
 * Note: This only seems to work when "Silent Switch" is disabled.
 *
 * Silent Switch: Determines whether the app goes silent when the silent
 * switch is turned on.  Also prevents sound playback from stopping when
 * the screen locks.
 *
 * Use Hardware: When enabled, the sound system will attempt to use the
 * hardware decoder if available (no iPod music playing).  If the hardware
 * is not being used, the sound system will take it, preventing iPod playback.
 * If the hardware is being used, the sound system will use software decoding.
 * 
 * The "Play/Stop" and "Paused" buttons control looping OpenAL and AVAudioPlayer
 * playback.
 *
 *
 * BUGS:
 *
 * There are cases where iOS behaves weirdly, as can be demonstrated here.
 *
 * Case 1: iPod ducking fails to unduck.
 *
 * Steps to reproduce:
 * - iPod Ducking: ON
 * - Silent Switch: OFF
 * - Switch to iPod player and start playing.
 * - Suspending/unsuspending causes iPod to duck or unduck.
 * - Playing BOTH an ALSource and an AudioTrack, then suspending, will prevent
 *   iPod from unducking.
 *
 *
 * Case 2: iOS fails to clear interrupt.
 *
 * Steps to reproduce:
 * - Turn off "Allow iPod", "Silent Switch", and "iPod Ducking".
 * - Switch to the mini ipod player and start it playing. This causes an interrupt.
 * - Stop music in mini ipod player and return to the app. This does NOT clear the interrupt.
 * System is still interrupted and will not play sounds.
 * To clear the interrupt, background the app and then open it again.
 * OALAudioSupport has a method "forceEndInterruption" to help with these sorts of situations.
 */
@interface AudioSessionDemo : CCLayer
{
	ALSource* source;
	ALBuffer* buffer;
	OALAudioTrack* track;
	
	LampButton* allowIpodButton;
	LampButton* ipodDuckingButton;
	LampButton* honorSilentSwitchButton;
	LampButton* useHardwareButton;
	LampButton* sessionActiveButton;
	LampButton* suspendedButton;
	
	LampButton* playStopSource;
	LampButton* pauseSource;
	
	LampButton* playStopTrack;
	LampButton* pauseTrack;
}

@end
