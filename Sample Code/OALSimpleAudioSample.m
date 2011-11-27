//
//  OALSimpleAudioSample.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-09.
//

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
