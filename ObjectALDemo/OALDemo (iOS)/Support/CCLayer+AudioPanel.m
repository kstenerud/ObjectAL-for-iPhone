//
//  CCLayer+AudioPanel.m
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "CCLayer+AudioPanel.h"


@implementation CCLayer (AudioPanel)

- (void) buildAudioPanel
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite* bg = [CCSprite spriteWithFile:@"panel-bg.png"];
	bg.anchorPoint = ccp(0,0);
	bg.position = ccp(0,0);
	[self addChild:bg];
	
	CCSprite* vtrim = [CCSprite spriteWithFile:@"panel-trim-vert.png"];
	vtrim.anchorPoint = ccp(0,0);
	vtrim.position = ccp(0,0);
	[self addChild:vtrim];
	
	vtrim = [CCSprite spriteWithFile:@"panel-trim-vert.png"];
	vtrim.anchorPoint = ccp(1,0);
	vtrim.position = ccp(screenSize.width,0);
	[self addChild:vtrim];
	
	CCSprite* htrim = [CCSprite spriteWithFile:@"panel-trim-horiz.png"];
	htrim.scaleX = (screenSize.width-vtrim.contentSize.width*2) / screenSize.width;
	htrim.anchorPoint = ccp(0,0);
	htrim.position = ccp(vtrim.contentSize.width, 1);
	[self addChild:htrim];
	
	htrim = [CCSprite spriteWithFile:@"panel-trim-horiz.png"];
	htrim.scaleX = (screenSize.width-vtrim.contentSize.width*2) / screenSize.width;
	htrim.anchorPoint = ccp(0,1);
	htrim.position = ccp(vtrim.contentSize.width, screenSize.height);
	[self addChild:htrim];
}

- (void) buildAudioPanelWithSeparator
{
	[self buildAudioPanel];
	[self buildPanelSeparator];
}

- (void) buildAudioPanelWithTSeparator
{
	[self buildAudioPanel];
	[self buildPanelTSeparator];
}

- (void) buildPanelSeparator
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite* vtrim = [CCSprite spriteWithFile:@"panel-trim-vert.png"];
	
	CCSprite* htrim = [CCSprite spriteWithFile:@"panel-trim-horiz.png"];
	htrim.scaleX = (screenSize.width-vtrim.contentSize.width*2) / screenSize.width;
	htrim.anchorPoint = ccp(0,0);
	htrim.position = ccp(vtrim.contentSize.width, 186);
	[self addChild:htrim];
}

- (void) buildPanelTSeparator
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CGPoint center = ccp(screenSize.width/2, screenSize.height/2);
	
	CCSprite* vtrim = [CCSprite spriteWithFile:@"panel-trim-vert.png"];
	vtrim.anchorPoint = ccp(0.5f,1);
	vtrim.position = ccp(center.x, 181);
	vtrim.textureRect = CGRectMake(vtrim.textureRect.origin.x,
								   vtrim.textureRect.origin.y,
								   vtrim.textureRect.size.width,
								   162);
	[self addChild:vtrim];
	
	CCSprite* htrim = [CCSprite spriteWithFile:@"panel-trim-horiz.png"];
	htrim.scaleX = (screenSize.width-vtrim.contentSize.width*2) / screenSize.width;
	htrim.anchorPoint = ccp(0,0);
	htrim.position = ccp(vtrim.contentSize.width, 186);
	[self addChild:htrim];
}

- (void) addPanelTitle:(NSString*) title
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CCLabelTTF* label = [CCLabelTTF labelWithString:title fontName:@"Helvetica-Bold" fontSize:24];
	label.position = ccp(screenSize.width/2, screenSize.height-kVOffset_Title);
	[self addChild:label];
}

- (void) addPanelLine1:(NSString*) str
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CCSprite* label = [CCLabelTTF labelWithString:str fontName:@"Helvetica" fontSize:20];
	label.position = ccp(screenSize.width/2, screenSize.height-kVOffset_Line1);
	[self addChild:label];
}

- (void) addPanelLine2:(NSString*) str
{
	CGSize screenSize = [[CCDirector sharedDirector] winSize];
	CCSprite* label = [CCLabelTTF labelWithString:str fontName:@"Helvetica" fontSize:20];
	label.position = ccp(screenSize.width/2, screenSize.height-kVOffset_Line2);
	[self addChild:label];
}


- (Slider*) panelSliderWithTarget:(id) target
						 selector:(SEL) selector
{
	CCSprite* track = [CCSprite spriteWithFile:@"panel-slider-track.png"];
	Slider* slider = [HorizontalSlider sliderWithTrack:track
												  knob:[CCSprite spriteWithFile:@"panel-slider-knob.png"]
											   padding:CGSizeMake(-6, 6)
												target:target
										  moveSelector:selector
										  dropSelector:selector];
//	slider.maxTravelProportion = 0.95f;	
	return slider;
}

- (Slider*) longPanelSliderWithTarget:(id) target
							 selector:(SEL) selector
{
	CCSprite* track = [CCSprite spriteWithFile:@"panel-slider-track-long.png"];
	Slider* slider = [HorizontalSlider sliderWithTrack:track
												  knob:[CCSprite spriteWithFile:@"panel-slider-knob.png"]
											   padding:CGSizeMake(-6, 6)
												target:target
										  moveSelector:selector
										  dropSelector:selector];
//	slider.maxTravelProportion = 0.98f;	
	return slider;
}

@end
