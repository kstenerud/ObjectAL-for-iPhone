//
//  LampButton.h
//  ObjectAL
//
//  Created by Karl Stenerud.
//

#import "Button.h"


@interface LampButton : Button
{
	CCLabelTTF* label;
	CCSprite* lampOn;
	CCSprite* lampOff;
}
@property(readwrite,assign) bool isOn;
@property(readonly) CCLabelTTF* label;

+ (id) buttonWithText:(NSString*) text
				 font:(NSString*) font
				 size:(float) fontSize
		   lampOnLeft:(bool) lampOnLeft
			   target:(id) target
			 selector:(SEL) selector;

- (id) initWithText:(NSString*) text
			   font:(NSString*) font
			   size:(float) fontSize
		 lampOnLeft:(bool) lampOnLeft
			 target:(id) targetIn
		   selector:(SEL) selectorIn;

@end
