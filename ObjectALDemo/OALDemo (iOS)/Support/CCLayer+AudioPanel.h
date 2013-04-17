//
//  CCLayer+AudioPanel.h
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "cocos2d.h"
#import "Slider.h"

#define kVOffset_Title 38
#define kVOffset_Line1 74
#define kVOffset_Line2 100

@interface CCLayer (AudioPanel)

- (void) buildAudioPanel;

- (void) buildAudioPanelWithSeparator;

- (void) buildAudioPanelWithTSeparator;

- (void) buildPanelSeparator;

- (void) buildPanelTSeparator;

- (Slider*) panelSliderWithTarget:(id) target
						 selector:(SEL) selector;

- (Slider*) longPanelSliderWithTarget:(id) target
							 selector:(SEL) selector;

- (void) addPanelTitle:(NSString*) title;

- (void) addPanelLine1:(NSString*) str;

- (void) addPanelLine2:(NSString*) str;

@end
