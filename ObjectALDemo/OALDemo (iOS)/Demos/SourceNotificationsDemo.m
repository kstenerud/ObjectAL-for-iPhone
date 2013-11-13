//
//  SourceNotificationsDemo.m
//  ObjectAL
//
//  Created by Karl Stenerud on 12-09-06.
//

#import "SourceNotificationsDemo.h"
#import <ObjectAL/ObjectAL.h>
#import "CCLayer+AudioPanel.h"
#import "ImageButton.h"
#import "MainLayer.h"
#import "CCLayer+Scene.h"
#import <ObjectAL/Support/OALTools.h>

#define MAX_RANDOM_REPEATS 2

@interface SourceNotificationsDemo ()

@property(nonatomic, readwrite, retain) ALSource* source;
@property(nonatomic, readwrite, retain) NSDictionary* buffers;
@property(nonatomic, readwrite, assign) CCLabelTTF* label;
@property(nonatomic, readwrite, assign) int randomRepeats;
@property(nonatomic, readwrite, assign) int lastRandomIndex;

@end

@implementation SourceNotificationsDemo

@synthesize source = _source;
@synthesize buffers = _buffers;
@synthesize label = _label;

#pragma mark Object Management

- (id) init
{
	if(nil != (self = [super initWithColor:ccc4(0, 0, 0, 0)]))
	{
		[self buildUI];
	}
	return self;
}

- (void) dealloc
{
	[_source release];
	[_buffers release];
	[super dealloc];
}

- (void) buildUI
{
	[self buildAudioPanelWithSeparator];
	[self addPanelTitle:@"Source Notifications"];
	[self addPanelLine1:@"Auto switches when playback completes"];

	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(size.width/2, size.height/2);

    CCLabelTTF* nowPlaying = [CCLabelTTF labelWithString:@"Now Playing"
                                                fontName:@"Helvetica"
                                                fontSize:34];
    nowPlaying.position = ccp(center.x, 160);
    [self addChild:nowPlaying];

	self.label = [CCLabelTTF labelWithString:@" "
                               fontName:@"Helvetica"
                               fontSize:22];
	self.label.position = ccp(center.x, 100);
    self.label.color = ccc3(255, 200, 50);
	[self addChild:self.label];

	// Exit button
	ImageButton* button = [ImageButton buttonWithImageFile:@"Exit.png" target:self selector:@selector(onExitPressed)];
	button.anchorPoint = ccp(1,1);
	button.position = ccp(size.width, size.height);
	[self addChild:button z:250];
}

#pragma mark Event Handlers

- (void) onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];

	// We'll let OALSimpleAudio deal with the device and context.
	// Since we're not going to use it for playing effects, don't give it any sources.
	[OALSimpleAudio sharedInstance].reservedSources = 0;

    // Whenever the source reaches the end of a buffer, call switchSegment.
    __block typeof(self) blockSelf = self;
    self.source = [ALSource source];
    [self.source registerNotification:AL_BUFFERS_PROCESSED
                             callback:^(__unused ALSource *source, __unused ALuint notificationID, __unused ALvoid *userData)
     {
         [blockSelf switchSegment];
     }
                             userData:nil];

    NSURL* url = [OALTools urlForPath:@"ColdFunk.caf"];
    OALAudioFile* file = [OALAudioFile fileWithUrl:url reduceToMono:NO];

    // I'm loading two segments from the same file so that they sound nice when
    // played after each other. You could also load buffers from multiple
    // different files.
    self.buffers = [NSDictionary dictionaryWithObjectsAndKeys:
                    [file bufferNamed:nil startFrame:0 numFrames:94505], @"First Part",
                    [file bufferNamed:nil startFrame:283402 numFrames:-1], @"Second Part",
                    nil];

    srand((unsigned int)time(NULL));
    [self switchSegment];
}

- (void) onExitPressed
{
	self.isTouchEnabled = NO;
	[[CCDirector sharedDirector] replaceScene:[MainLayer scene]];
}

/** Somewhat random index chooser that doesn't allow long runs of the same
 * value.
 */
- (int) randomIndex
{
    int index = rand() & 1;
    if(index == self.lastRandomIndex)
    {
        self.randomRepeats++;
        if(self.randomRepeats > MAX_RANDOM_REPEATS)
        {
            index = (index + 1) & 1;
        }
    }
    if(index != self.lastRandomIndex)
    {
        self.lastRandomIndex = index;
        self.randomRepeats = 0;
    }
    return index;
}

- (void) switchSegment
{
    // Pick one of the two segments at random and play
    NSString* name = [[self.buffers allKeys] objectAtIndex:(NSUInteger)[self randomIndex]];
    [self.source play:[self.buffers objectForKey:name]];

    // This method may not be called on the main thread, so we need to defer
    // any cocos2d updates to be run on the main thread.
    [self.label performSelectorOnMainThread:@selector(setString:)
                                 withObject:name
                              waitUntilDone:NO];
}

@end
