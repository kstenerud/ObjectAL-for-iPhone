//
//  OALAudioFile.h
//  ObjectAL
//
//  Created by Karl Stenerud on 10-12-24.
//
// Copyright 2010 Karl Stenerud
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ALBuffer.h"


/**
 * Maintains an open audio file and allows loading data from that file into
 * new ALBuffer objects.
 */
@interface OALAudioFile : NSObject
{
	NSURL* url;
	bool reduceToMono;
	SInt64 totalFrames;

	/** A description of the audio data in this file. */
	AudioStreamBasicDescription streamDescription;

	/** The OS specific file handle */
	ExtAudioFileRef fileHandle;

	/** The actual number of channels in the audio data if not reducing to mono */
	UInt32 originalChannelsPerFrame;
}

/** The URL of the audio file */
@property(readonly) NSURL* url;

/** A description of the audio data in this file. */
@property(readonly) AudioStreamBasicDescription* streamDescription;

/** The total number of audio frames in this file */
@property(readonly) SInt64 totalFrames;

/** If YES, reduce any stereo data to mono (stereo samples don't support panning or positional audio). */
@property(readwrite,assign) bool reduceToMono;

/** Open the audio file at the specified URL.
 *
 * @param url The URL to open the audio file from.
 * @param reduceToMono If YES, reduce any stereo track to mono
                       (stereo samples don't support panning or positional audio).
 * @return a new audio file object.
 */
+ (OALAudioFile*) fileWithUrl:(NSURL*) url
				 reduceToMono:(bool) reduceToMono;

/** Initialize this object with the audio file at the specified URL.
 *
 * @param url The URL to open the audio file from.
 * @param reduceToMono If YES, reduce any stereo track to mono
                       (stereo samples don't support panning or positional audio).
 * @return the initialized audio file object.
 */
- (id) initWithUrl:(NSURL*) url
	  reduceToMono:(bool) reduceToMono;

/** Read audio data from this file into a new buffer.
 *
 * @param startFrame The starting audio frame to read data from.
 * @param numFrames The number of frames to read.
 * @param bufferSize On successful return, contains the size of the returned buffer, in bytes.
 * @return The audio data or nil on error.  You are responsible for calling free() on the data.
 */
- (void*) audioDataWithStartFrame:(SInt64) startFrame
						numFrames:(SInt64) numFrames
					   bufferSize:(UInt32*) bufferSize;

/** Create a new ALBuffer with the contents of this file.
 *
 * @param name The name to be given to this ALBuffer.
 * @param startFrame The starting audio frame to read data from.
 * @param numFrames The number of frames to read.
 * @return a new ALBuffer containing the audio data.
 */
- (ALBuffer*) bufferNamed:(NSString*) name
			   startFrame:(SInt64) startFrame
				numFrames:(SInt64) numFrames;

/** Close any OS resources in use by this object.
 * Any operations called on this object after closing will likely fail.
 */
- (void) close;

/** Convenience method to load the entire contents of a URL into a new ALBuffer.
 *
 * @param url The URL to open the audio file from.
 * @param reduceToMono If YES, reduce any stereo track to mono
                       (stereo samples don't support panning or positional audio).
 * @return an ALBuffer object.
 */
+ (ALBuffer*) bufferFromUrl:(NSURL*) url
			   reduceToMono:(bool) reduceToMono;

@end
