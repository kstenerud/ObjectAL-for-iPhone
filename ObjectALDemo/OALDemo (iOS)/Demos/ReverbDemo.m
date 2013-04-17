//
//  ReverbDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 1/28/12.
//

#import "ReverbDemo.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import "Slider.h"
#import "ImageButton.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"


#pragma mark Private Methods

@interface ReverbDemo (Private)

/** Build the user interface. */
- (void) buildUI;

/** Exit the demo. */
- (void) onExitPressed;

/** Change the volume. */
- (void) onVolumeChanged:(Slider*) slider;

/** Change the pitch. */
- (void) onPitchChanged:(Slider*) slider;

/** Change the pan. */
- (void) onPanChanged:(Slider*) slider;

/** Add a room to the list of room types */
- (void) addRoomType:(ALint) roomType named:(NSString*) name;

/** Set the room type based on UI settings */
- (void) updateRoomType;

@end


#pragma mark -
#pragma mark VolumePitchPanDemo

@implementation ReverbDemo

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{
        roomTypeNames = [[NSMutableDictionary alloc] init];
        roomTypeOrder = [[NSMutableArray alloc] init];
        
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_SmallRoom named:@"Small Room"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_MediumRoom named:@"Medium Room"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_LargeRoom named:@"Large Room"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_LargeRoom2 named:@"Large Room 2"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_MediumHall named:@"Medium Hall"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_MediumHall2 named:@"Medium Hall 2"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_MediumHall3 named:@"Medium Hall 3"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_LargeHall named:@"Large Hall"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_LargeHall2 named:@"Large Hall 2"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_MediumChamber named:@"Medium Chamber"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_LargeChamber named:@"Large Chamber"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_Cathedral named:@"Cathedral"];
        [self addRoomType:ALC_ASA_REVERB_ROOM_TYPE_Plate named:@"Plate"];
        
        [self buildUI];
	}
	return self;
}

- (void) dealloc
{
	[source release];
    [roomTypeOrder release];
    [roomTypeNames release];
    
	[super dealloc];
}

- (void) addRoomType:(ALint) roomType named:(NSString*) name
{
    NSNumber* roomTypeNumber = [NSNumber numberWithInt:roomType];
    [roomTypeOrder addObject:roomTypeNumber];
    [roomTypeNames setObject:name forKey:roomTypeNumber];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Reverb (iOS 5+)"];
	[self addPanelLine1:@"Use the sliders to alter reverb."];
	[self addPanelLine2:@"Use buttons to select room type."];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
    
	CCLabelTTF* label;
	Slider* slider;
    
	CGPoint pos = ccp(170, 140);
	
	label = [CCLabelTTF labelWithString:@"Global Reverb" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
	slider = [self panelSliderWithTarget:self selector:@selector(onGlobalReverbChanged:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x +4, pos.y);
	slider.value = 0.5f;
	[self addChild:slider];
    
	pos.y -= 50;
    
	label = [CCLabelTTF labelWithString:@"Send Level" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
	slider = [self panelSliderWithTarget:self selector:@selector(onSendLevelChanged:)];
	slider.anchorPoint = ccp(0,0);
	slider.position = ccp(pos.x + 4, pos.y);
	slider.value = 1.0f;
	[self addChild:slider];
    
	pos.y -= 50;
	
	label = [CCLabelTTF labelWithString:@"Room Type" fontName:@"Helvetica" fontSize:20];
	label.anchorPoint = ccp(1, 0);
	label.position = ccp(pos.x - 4, pos.y);
	[self addChild:label];
	
    Button* button = [ImageButton buttonWithImageFile:@"Back.png" target:self selector:@selector(onPreviousRoom:)];
    button.position = ccp(pos.x + button.contentSize.width / 2 + 10,
                          pos.y + label.contentSize.height / 2);
    [self addChild:button];

	roomLabel = [CCLabelTTF labelWithString:@"Medium Chamber" fontName:@"Helvetica" fontSize:20];
	roomLabel.anchorPoint = ccp(0.5, 0);
	roomLabel.position = ccp(pos.x + 140, pos.y);
	[self addChild:roomLabel];
	
    button = [ImageButton buttonWithImageFile:@"Next.png" target:self selector:@selector(onNextRoom:)];
    button.position = ccp(pos.x + button.contentSize.width + 200,
                          pos.y + label.contentSize.height / 2);
    [self addChild:button];
    
    
	// Exit button
	button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}


#pragma mark Event Handlers

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;
    
    // Turn on reverb.
    [OALSimpleAudio sharedInstance].context.listener.reverbOn = YES;
    
    // Set global reverb level to "normal" (0dB)
    [OALSimpleAudio sharedInstance].context.listener.globalReverbLevel = 0;
	
	source = [[ALSource source] retain];
    
    // Source starts off with full reverb send level.
    // ALSource also supports reverbOcclusion and reverbObstruction, which are
    // not used in this demo.
    source.reverbSendLevel = 1.0;

    // Set our initial room type (small room since index is 0).
    // Room type is a coarse setting. You can also finetune by setting reverbEQGain,
    // reverbEQFrequency, and reverbEQBandwidth on the ALListener object.
    [self updateRoomType];
	
	// Reverb requires mono data, so we have to force ColdFunk.caf from stereo to mono.

    // We'll use OALSimpleAudio to load the data. It will cache the buffer so that
    // any future calls to preload will fetch from cache instead. Not strictly needed
    // here, but useful to know.
	ALBuffer* buffer = [[OALSimpleAudio sharedInstance] preloadEffect:@"ColdFunk.caf" reduceToMono:YES];
	
	[source play:buffer loop:YES];
}

- (void) onSendLevelChanged:(Slider*) slider
{
	source.reverbSendLevel = slider.value;
}

- (void) onGlobalReverbChanged:(Slider*) slider
{
    float level;
    if(slider.value <= 0.5)
    {
        level = slider.value * 80 - 40;
    }
    else
    {
        // Don't allow global reverb level to go above 5dB since it starts to distort.
        level = slider.value * 10;
    }
    
    [OALSimpleAudio sharedInstance].context.listener.globalReverbLevel = level;
}

- (void) updateRoomType
{
    if(roomIndex < 0)
    {
        roomIndex = (int)[roomTypeOrder count] - 1;
    }
    else if(roomIndex >= (int)[roomTypeOrder count])
    {
        roomIndex = 0;
    }

    NSNumber* roomType = [roomTypeOrder objectAtIndex:(NSUInteger)roomIndex];
    [OALSimpleAudio sharedInstance].context.listener.reverbRoomType = [roomType intValue];
    
    [roomLabel setString:[roomTypeNames objectForKey:roomType]];
}

- (void) onPreviousRoom:(__unused id) sender
{
    roomIndex--;
    [self updateRoomType];
}

- (void) onNextRoom:(__unused id) sender
{
    roomIndex++;
    [self updateRoomType];
}

@end
