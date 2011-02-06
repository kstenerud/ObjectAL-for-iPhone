//
//  OpenALAudioTrackSample.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-09.
//

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
		// Note that it's easier to just let OALSimpleAudio handle
		// these rather than make and manage them yourself.
		device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
		context = [[ALContext contextOnDevice:device attributes:nil] retain];
		[OpenALManager sharedInstance].currentContext = context;
		
		// Deal with interruptions for me!
		[OALAudioSession sharedInstance].handleInterruptions = YES;
		
		// We don't want ipod music to keep playing since
		// we have our own bg music.
		[OALAudioSession sharedInstance].allowIpod = NO;
		
		// Mute all audio if the silent switch is turned on.
		[OALAudioSession sharedInstance].honorSilentSwitch = YES;
		
		// Take all 32 sources for this channel.
		// (we probably won't use that many but what the heck!)
		channel = [[ALChannelSource channelWithSources:32] retain];
		
		// Preload the buffers so we don't have to load and play them later.
		shootBuffer = [[[OpenALManager sharedInstance]
						bufferFromFile:SHOOT_SOUND] retain];
		explosionBuffer = [[[OpenALManager sharedInstance]
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
