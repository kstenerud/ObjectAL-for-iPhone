//
//  AudioTrackDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 10-09-19.
//

#import "AudioTrackDemo.h"
#import "MainScene.h"
#import "CCLayer+Scene.h"
#import "ImageAndLabelButton.h"
#import "Slider.h"
#import "ObjectAL.h"
#import "LampButton.h"
#import "CCLayer+AudioPanel.h"


#pragma mark Private Methods

@interface AudioTrackDemo (Private)

/** Add and register an audio track + file. */
- (void) addTrack:(NSString*) filename;

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Play or stop a track. */
- (void) onPlayStop:(LampButton*) button;

/** Change the playback volume of a track. */
- (void) onChangeVolume:(Slider*) slider;

@end

#pragma mark -
#pragma mark AudioTrackDemo

@implementation AudioTrackDemo

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{		
		audioTracks = [[NSMutableArray arrayWithCapacity:10] retain];
		audioTrackFiles = [[NSMutableArray arrayWithCapacity:10] retain];
		buttons = [[NSMutableArray arrayWithCapacity:10] retain];
		sliders = [[NSMutableArray arrayWithCapacity:10] retain];

		// You could do all mp3 or any other format supported by iOS software decoding.
		// Any format requiring the hardware will only work on the first track that starts playing.
		[self addTrack:@"ColdFunk.caf"];
		[self addTrack:@"HappyAlley.caf"];
		[self addTrack:@"PlanetKiller.mp3"];

		[self buildUI];
	}
	return self;
}

- (void) dealloc
{
	[audioTracks release];
	[audioTrackFiles release];
	[buttons release];
	[sliders release];
	[super dealloc];
}

- (void) addTrack:(NSString*) filename
{
	// Make the audio tracks auto-preload so that they start as fast
	// as possible when the button is pressed, even after stopping
	// playback.
	OALAudioTrack* track = [OALAudioTrack track];
	[track preloadFile:filename];
	track.autoPreload = YES;
	
	// Loop forever when playing.
	track.numberOfLoops = -1;

	[audioTrackFiles addObject:filename];
	[audioTracks addObject:track];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Background Audio Tracks"];
	[self addPanelLine1:@"Click a filename to start/stop."];
	[self addPanelLine2:@"Use slider for volume."];	
	
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float xPos = 40;
	float yPos = screenSize.height - 170;
	float maxWidth = 0;
	
	for(uint i = 0; i < [audioTracks count]; i++)
	{
		LampButton* button = [LampButton buttonWithText:[audioTrackFiles objectAtIndex:i]
												   font:@"Helvetica"
												   size:20
											 lampOnLeft:NO
												 target:self
											   selector:@selector(onPlayStop:)];

		[buttons addObject:button];
		[self addChild:button];
		if(button.contentSize.width > maxWidth)
		{
			maxWidth = button.contentSize.width;
		}
		
		Slider* slider = [self panelSliderWithTarget:self selector:@selector(onChangeVolume:)];
		[sliders addObject:slider];
		[self addChild:slider];

		button.position = ccp(xPos + button.contentSize.width/2, yPos);
		slider.position = ccp(button.position.x + button.contentSize.width/2 + 6, yPos);
		
		yPos -= 50;
	}

	for(CCNode* button in buttons)
	{
		button.position = ccp(xPos + button.contentSize.width/2 + maxWidth - button.contentSize.width, button.position.y);
	}

	for(Slider* slider in sliders)
	{
		slider.position = ccp(xPos + slider.contentSize.width*slider.scaleX/2 + maxWidth + 6, slider.position.y);
		slider.value = 1.0f;
	}

	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(screenSize.width, screenSize.height);
	[self addChild:button z:250];
}

- (void) onEnterTransitionDidFinish
{
}

- (void) onPlayStop:(LampButton*) button
{
	int index = [buttons indexOfObject:button];
	if(NSNotFound != index)
	{
		OALAudioTrack* track = [audioTracks objectAtIndex:index];
		if(button.isOn)
		{
			[track play];
		}
		else
		{
			[track stop];
		}
	}
}

- (void) onChangeVolume:(Slider*) slider
{
	int index = [sliders indexOfObject:slider];
	if(NSNotFound != index)
	{
		OALAudioTrack* track = [audioTracks objectAtIndex:index];
		track.gain = slider.value;
	}
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
