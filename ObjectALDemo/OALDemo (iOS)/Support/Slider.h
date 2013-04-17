//
//  Slider.h
//
//  Created by Karl Stenerud on 10-05-30.
//

#import "TouchableNode.h"

/**
 * A slider control.  Contains a "knob" object, which slides along a "track" object.
 * Both the track and the knob are supplied at object creation time, and the slider
 * adjusts its contentSize according to the knob and track's size as well as their scale factor. <br>
 * This means that you can prescale the knob and/or track and still have a functioning slider.
 */
@interface Slider : SingleTouchableNode <CCRGBAProtocol>

/** The position (value) of the slider in the track, as a proportion from 0.0 to 1.0 */
@property(nonatomic,readwrite,assign) float value;

/** Create a slider.
 * @param track The node to use as a track.
 * @param knob The node to use as a knob.
 * @param padding The amount of padding to add to the touchable area.
 * @param target the target to notify of events.
 * @param moveSelector the selector to call when the knob is moved (nil = ignore).
 * @param dropSelector The selector to call when the knob is dropped (nil = ignore).
 * @return a new slider.
 */
+ (id) sliderWithTrack:(CCNode*) track
				  knob:(CCNode*) knob
			   padding:(CGSize) padding
				target:(id) target
		  moveSelector:(SEL) moveSelector
		  dropSelector:(SEL) dropSelector;

/** Initialize a slider.
 * @param track The node to use as a track.
 * @param knob The node to use as a knob.
 * @param padding The amount of padding to add to the touchable area.
 * @param target the target to notify of events.
 * @param moveSelector the selector to call when the knob is moved (nil = ignore).
 * @param dropSelector The selector to call when the knob is dropped (nil = ignore).
 * @return The initialized slider.
 */
- (id) initWithTrack:(CCNode*) track
				knob:(CCNode*) knob
			 padding:(CGSize) padding
			  target:(id) target
		moveSelector:(SEL) moveSelector
		dropSelector:(SEL) dropSelector;

@end

/**
 * A slider that operates in the vertical direction.
 */
@interface VerticalSlider: Slider
{
	float horizontalLock;
	float verticalMax;
	float verticalMin;
}

@end


/**
 * A slider that operates in the horizontal direction.
 */
@interface HorizontalSlider: Slider
{
	float verticalLock;
	float horizontalMax;
	float horizontalMin;
}

@end
