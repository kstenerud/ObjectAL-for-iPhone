//
//  ALBuffer.h
//  ObjectAL
//
//  Created by Karl Stenerud on 15/12/09.
//
// Copyright 2009 Karl Stenerud
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Note: You are NOT required to make the license available from within your
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>

@class ALDevice;


#pragma mark ALBuffer

/**
 * A buffer for audio data that will be played via a SoundSource.
 * @see SoundSource
 */
@interface ALBuffer : NSObject
{
	ALDevice* device;
	ALuint bufferId;
	NSString* name;
	ALenum format;
	/** The uncompressed sound data to play. */
	void* bufferData;
}


#pragma mark Properties

/** The size of a sample in bits. */
@property(readonly) ALuint bits;

/** The ID assigned to this buffer by OpenAL. */
@property(readonly) ALuint bufferId;

/** The number of channels the buffer data plays in. */
@property(readonly) ALuint channels;

/** The device this buffer was created for. */
@property(readonly) ALDevice* device;

/** The format of the audio data (see al.h, AL_FORMAT_XXX). */
@property(readonly) ALenum format;

/** The frequency this buffer runs at. */
@property(readonly) ALuint frequency;

/** The name given to this buffer upon creation.  You may change it at runtime if you wish. */
@property(readwrite,retain) NSString* name;

/** The size, in bytes, of the currently loaded buffer data. */
@property(readonly) ALuint size;


#pragma mark Object Management

/** Make a new buffer.
 *
 * @param name Optional name that you can use to identify this buffer in your code.
 * @param data The sound data.  Note: ALBuffer will call free() on this data when it is destroyed!
 * @param size The size of the data in bytes.
 * @param format The format of the data (see the Core Audio documentation).
 * @param frequency The sampling frequency in Hz.
 * @return A new buffer.
 */
+ (id) bufferWithName:(NSString*) name
				 data:(void*) data
				 size:(ALsizei) size
			   format:(ALenum) format
			frequency:(ALsizei) frequency;

/** Initialize the buffer.
 *
 * @param name Optional name that you can use to identify this buffer in your code.
 * @param data The sound data.  Note: ALBuffer will call free() on this data when it is destroyed!
 * @param size The size of the data in bytes.
 * @param format The format of the data (see the Core Audio documentation).
 * @param frequency The sampling frequency in Hz.
 * @return The initialized buffer.
 */
- (id) initWithName:(NSString*) name
			   data:(void*) data
			   size:(ALsizei) size
			 format:(ALenum) format
		  frequency:(ALsizei) frequency;

@end
