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

#pragma mark Private Methods

@interface AudioTrackDemo (Private)

- (void) addTrack:(NSString*) filename;
- (void) buildUI;

@end

#pragma mark -
#pragma mark AudioTrackDemo

@implementation AudioTrackDemo

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(255, 255, 255, 255)]))
	{		
		audioTracks = [[NSMutableArray arrayWithCapacity:10] retain];
		audioTrackFiles = [[NSMutableArray arrayWithCapacity:10] retain];
		buttons = [[NSMutableArray arrayWithCapacity:10] retain];
		sliders = [[NSMutableArray arrayWithCapacity:10] retain];

		// You could do all mp3 or any other format supported by iOS software decoding.
		// Any format requiring the hardware will only work on the first track that starts playing.
		[self addTrack:@"ColdFunk.wav"];
		[self addTrack:@"HappyAlley.wav"];
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
	[audioTrackFiles addObject:filename];
	[audioTracks addObject:[OALAudioTrack track]];
}

- (void) buildUI
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	float xPos = 20;
	float yPos = screenSize.height - 140;
	float maxWidth = 0;
	
	CCLabel* label = [CCLabel labelWithString:@"Background audio tracks" fontName:@"Helvetica" fontSize:24];
	label.position = ccp(screenSize.width/2, screenSize.height-20);
	label.color = ccBLACK;
	[self addChild:label];

	label = [CCLabel labelWithString:@"Click name to start." fontName:@"Helvetica" fontSize:20];
	label.position = ccp(screenSize.width/2, screenSize.height-60);
	label.color = ccBLACK;
	[self addChild:label];
	
	label = [CCLabel labelWithString:@"Use slider for volume." fontName:@"Helvetica" fontSize:20];
	label.position = ccp(screenSize.width/2, screenSize.height-84);
	label.color = ccBLACK;
	[self addChild:label];
	
	
	for(uint i = 0; i < [audioTracks count]; i++)
	{
		label = [CCLabel labelWithString:[audioTrackFiles objectAtIndex:i] fontName:@"Helvetica" fontSize:24];
		label.color = ccBLACK;
		ImageAndLabelButton* button = [ImageAndLabelButton buttonWithImageFile:@"Jupiter.png"
																		 label:label
																		target:self
																	  selector:@selector(onPlayStop:)];
		[buttons addObject:button];
		[self addChild:button];
		if(button.contentSize.width > maxWidth)
		{
			maxWidth = button.contentSize.width;
		}
		
		CCSprite* track = [CCSprite spriteWithFile:@"SliderTrackHorizontal.png"];
		Slider* slider = [HorizontalSlider sliderWithTrack:track
													  knob:[CCSprite spriteWithFile:@"SliderKnobHorizontal.png"]
													target:self
											  moveSelector:@selector(onChangeVolume:)
											  dropSelector:@selector(onChangeVolume:)];
		slider.scale = 1.8f;
		[sliders addObject:slider];
		[self addChild:slider];

		button.position = ccp(xPos + button.contentSize.width/2, yPos);
		slider.position = ccp(button.position.x + button.contentSize.width/2 + 20, yPos);
		
		yPos -= 60;
	}

	for(Slider* slider in sliders)
	{
		slider.position = ccp(slider.contentSize.width*slider.scaleX/2 + xPos + maxWidth + 20, slider.position.y);
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

- (void) onPlayStop:(ImageAndLabelButton*) sender
{
	int index = [buttons indexOfObject:sender];
	if(NSNotFound != index)
	{
		OALAudioTrack* track = [audioTracks objectAtIndex:index];
		if(track.playing)
		{
			[track stop];
		}
		else
		{
			[track playFile:[audioTrackFiles objectAtIndex:index] loops:-1];
		}
	}
}

- (void) onChangeVolume:(Slider*) sender
{
	int index = [sliders indexOfObject:sender];
	if(NSNotFound != index)
	{
		OALAudioTrack* track = [audioTracks objectAtIndex:index];
		track.gain = sender.value;
	}
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

@end
