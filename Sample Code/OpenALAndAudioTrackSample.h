//
//  OpenALAudioTrackSample.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-10-09.
//

#import <Foundation/Foundation.h>
#import "ObjectAL.h"


/**
 * This is a copy of the sample code presented in the ObjectAL documentation.
 */
@interface OpenALAudioTrackSample : NSObject
{
	// Sound Effects
	ALDevice* device;
	ALContext* context;
	ALChannelSource* channel;
	ALBuffer* shootBuffer;	
	ALBuffer* explosionBuffer;

	// Background Music
	OALAudioTrack* musicTrack;
}

@end
