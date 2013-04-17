//
//  ReverbDemo.h
//  ObjectAL
//
//  Created by Karl Stenerud on 1/28/12.
//

#import "cocos2d.h"
#import <ObjectAL/ObjectAL.h>

/**
 * Demo of new reverb controls in iOS 5.
 * Global reverb level is the master reverb control.
 * Send level controls how much of a source's output is passed through reverb processing.
 * The room type controls which room effect to apply.
 */
@interface ReverbDemo : CCLayerColor
{
	ALSource* source;
    NSMutableArray* roomTypeOrder;
    NSMutableDictionary* roomTypeNames;
    int roomIndex;
    CCLabelTTF* roomLabel;
}

@end
