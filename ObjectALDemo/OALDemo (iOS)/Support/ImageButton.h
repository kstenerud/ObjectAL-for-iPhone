//
//  ImageButton.h
//
//  Created by Karl Stenerud on 10-05-29.
//

#import "Button.h"

/**
 * A button with a convenience method to use a sprite as the touchable portion.
 */
@interface ImageButton : Button
{
}

/** Create a new image button.
 * @param filename the filename of the image to use as a touchable portion.
 * @param target the target to notify when the button is pressed.
 * @param selector the selector to call when the button is pressed.
 * @return a new button.
 */
+ (id) buttonWithImageFile:(NSString*) filename target:(id) target selector:(SEL) selector;

/** Initialize an image button.
 * @param filename the filename of the image to use as a touchable portion.
 * @param target the target to notify when the button is pressed.
 * @param selector the selector to call when the button is pressed.
 * @return the initialized button.
 */
- (id) initWithImageFile:(NSString*) filename target:(id) target selector:(SEL) selector;

@end
