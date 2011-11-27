//
//  ImageAndTextButton.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-08-17.
//

#import "Button.h"


@interface ImageAndLabelButton : Button
{
	CCLabelTTF* label;
}

@property(readonly) CCLabelTTF* label;

/** Create a new button.
 * @param filename the filename of the image to use as a touchable portion.
 * @param label the label to display to the right of the image.
 * @param target the target to notify when the button is pressed.
 * @param selector the selector to call when the button is pressed.
 * @return a new button.
 */
+ (id) buttonWithImageFile:(NSString*) filename label:(CCLabelTTF*) label target:(id) target selector:(SEL) selector;

/** Initialize a button.
 * @param filename the filename of the image to use as a touchable portion.
 * @param label the label to display to the right of the image.
 * @param target the target to notify when the button is pressed.
 * @param selector the selector to call when the button is pressed.
 * @return the initialized button.
 */
- (id) initWithImageFile:(NSString*) filename label:(CCLabelTTF*) label target:(id) target selector:(SEL) selector;

@end
