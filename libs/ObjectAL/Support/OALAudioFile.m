//
//  OALAudioFile.m
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

#import "OALAudioFile.h"
#import "ObjectALMacros.h"


/**
 * (INTERNAL USE) Private methods for OALAudioFile. 
 */
@interface OALAudioFile (Private)

/** (INTERNAL USE) Close any resources belonging to the OS.
 */
- (void) closeOSResources;

@end


@implementation OALAudioFile

+ (OALAudioFile*) fileWithUrl:(NSURL*) url
				 reduceToMono:(bool) reduceToMono
{
	return [[[self alloc] initWithUrl:url reduceToMono:reduceToMono] autorelease];
}


- (id) initWithUrl:(NSURL*) urlIn
	  reduceToMono:(bool) reduceToMonoIn
{
	if(nil != (self = [super init]))
	{
		url = [urlIn retain];
		reduceToMono = reduceToMonoIn;

		OSStatus error;
		UInt32 size;
		
		if(nil == url)
		{
			OAL_LOG_ERROR(@"Cannot open NULL file / url");
			goto done;
		}

		// Open the file
		if(noErr != (error = ExtAudioFileOpenURL((CFURLRef)url, &fileHandle)))
		{
			REPORT_EXTAUDIO_CALL(error, @"Could not open url %@", url);
			goto done;
		}

		// Get some info about the file
		size = sizeof(SInt64);
		if(noErr != (error = ExtAudioFileGetProperty(fileHandle,
													 kExtAudioFileProperty_FileLengthFrames,
													 &size,
													 &totalFrames)))
		{
			REPORT_EXTAUDIO_CALL(error, @"Could not get frame count for file (url = %@)", url);
			goto done;
		}
		
		
		size = sizeof(AudioStreamBasicDescription);
		if(noErr != (error = ExtAudioFileGetProperty(fileHandle,
													 kExtAudioFileProperty_FileDataFormat,
													 &size,
													 &streamDescription)))
		{
			REPORT_EXTAUDIO_CALL(error, @"Could not get audio format for file (url = %@)", url);
			goto done;
		}
		
		// Specify the new audio format (anything not changed remains the same)
		streamDescription.mFormatID = kAudioFormatLinearPCM;
		streamDescription.mFormatFlags = kAudioFormatFlagsNativeEndian |
		kAudioFormatFlagIsSignedInteger |
		kAudioFormatFlagIsPacked;
		// Force to 16 bit since iOS doesn't seem to like 8 bit.
		streamDescription.mBitsPerChannel = 16;

		originalChannelsPerFrame = streamDescription.mChannelsPerFrame > 2 ? 2 : streamDescription.mChannelsPerFrame;
		if(reduceToMono)
		{
			streamDescription.mChannelsPerFrame = 1;
		}
		
		if(streamDescription.mChannelsPerFrame > 2)
		{
			// Don't allow more than 2 channels (stereo)
			OAL_LOG_WARNING(@"Audio stream in %@ contains %d channels. Capping at 2",
							url,
							streamDescription.mChannelsPerFrame);
			streamDescription.mChannelsPerFrame = 2;
		}

		streamDescription.mBytesPerFrame = streamDescription.mChannelsPerFrame * streamDescription.mBitsPerChannel / 8;
		streamDescription.mFramesPerPacket = 1;
		streamDescription.mBytesPerPacket = streamDescription.mBytesPerFrame * streamDescription.mFramesPerPacket;
		
		// Set the new audio format
		if(noErr != (error = ExtAudioFileSetProperty(fileHandle,
													 kExtAudioFileProperty_ClientDataFormat,
													 sizeof(AudioStreamBasicDescription),
													 &streamDescription)))
		{
			REPORT_EXTAUDIO_CALL(error, @"Could not set new audio format for file (url = %@)", url);
			goto done;
		}
		
	done:
		if(noErr != error)
		{
			[self release];
			return nil;
		}
		
	}
	return self;
}

- (void) dealloc
{
	[self closeOSResources];

	[url release];

	[super dealloc];
}

- (void) closeOSResources
{
	@synchronized(self)
	{
		if(nil != fileHandle)
		{
			REPORT_EXTAUDIO_CALL(ExtAudioFileDispose(fileHandle), @"Error closing file (url = %@)", url);
			fileHandle = nil;
		}
	}
}

- (void) close
{
	[self closeOSResources];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@: %p: %@>", [self class], self, url];
}

@synthesize url;

- (AudioStreamBasicDescription*) streamDescription
{
	return &streamDescription;
}

@synthesize totalFrames;

- (bool) reduceToMono
{
	return reduceToMono;
}

- (void) setReduceToMono:(bool) value
{
	@synchronized(self)
	{
		if(value != reduceToMono)
		{
			OSStatus error;
			reduceToMono = value;
			streamDescription.mChannelsPerFrame = reduceToMono ? 1 : originalChannelsPerFrame;
			if(noErr != (error = ExtAudioFileSetProperty(fileHandle,
														 kExtAudioFileProperty_ClientDataFormat,
														 sizeof(AudioStreamBasicDescription),
														 &streamDescription)))
			{
				REPORT_EXTAUDIO_CALL(error, @"Could not set new audio format for file (url = %@)", url);
			}
		}
	}
}

- (void*) audioDataWithStartFrame:(SInt64) startFrame
						numFrames:(SInt64) numFrames
					   bufferSize:(UInt32*) bufferSize
{
	@synchronized(self)
	{
		if(nil == fileHandle)
		{
			OAL_LOG_ERROR(@"Attempted to read from closed file. Returning nil (url = %@)", url);
			return nil;
		}
		
		OSStatus error;
		UInt32 numFramesRead;
        AudioBufferList bufferList;
        UInt32 bufferOffset = 0;

		
		// < 0 means read to the end of the file.
		if(numFrames < 0)
		{
			numFrames = totalFrames - startFrame;
		}
		
		// Allocate some memory to hold the data
		UInt32 streamSizeInBytes = (UInt32)(streamDescription.mBytesPerFrame * numFrames);
		void* streamData = malloc(streamSizeInBytes);
		if(nil == streamData)
		{
			OAL_LOG_ERROR(@"Could not allocate %d bytes for audio buffer from file (url = %@)",
						  streamSizeInBytes,
						  url);
			goto onFail;
		}
		
		if(noErr != (error = ExtAudioFileSeek(fileHandle, startFrame)))
		{
			REPORT_EXTAUDIO_CALL(error, @"Could not seek to %ll in file (url = %@)",
								 startFrame,
								 url);
			goto onFail;
		}
		
        
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mNumberChannels = streamDescription.mChannelsPerFrame;
        for(UInt32 framesToRead = (UInt32) numFrames; framesToRead > 0; framesToRead -= numFramesRead)
        {
            bufferList.mBuffers[0].mDataByteSize = streamDescription.mBytesPerFrame * framesToRead;
            bufferList.mBuffers[0].mData = streamData + bufferOffset;
            
            numFramesRead = framesToRead;
            if(noErr != (error = ExtAudioFileRead(fileHandle, &numFramesRead, &bufferList)))
            {
                REPORT_EXTAUDIO_CALL(error, @"Could not read audio data in file (url = %@)",
                                     url);
                goto onFail;
            }
            bufferOffset += streamDescription.mBytesPerFrame * numFramesRead;
            if(numFramesRead == 0)
            {
                // Sometimes the stream description was wrong and you hit an EOF prematurely
                break;
            }
        }
		
		if(nil != bufferSize)
		{
            // Use however many bytes were actually read
			*bufferSize = bufferOffset;
		}
		
		return streamData;
		
	onFail:
		if(nil != streamData)
		{
			free(streamData);
		}
		return nil;
	}
}


- (ALBuffer*) bufferNamed:(NSString*) name
			   startFrame:(SInt64) startFrame
				numFrames:(SInt64) numFrames
{
	@synchronized(self)
	{
		if(nil == fileHandle)
		{
			OAL_LOG_ERROR(@"Attempted to read from closed file. Returning nil (url = %@)", url);
			return nil;
		}
		
		UInt32 bufferSize;
		void* streamData = [self audioDataWithStartFrame:startFrame numFrames:numFrames bufferSize:&bufferSize];
		if(nil == streamData)
		{
			return nil;
		}
		
		ALenum audioFormat;
		if(1 == streamDescription.mChannelsPerFrame)
		{
			if(8 == streamDescription.mBitsPerChannel)
			{
				audioFormat = AL_FORMAT_MONO8;
			}
			else
			{
				audioFormat = AL_FORMAT_MONO16;
			}
		}
		else
		{
			if(8 == streamDescription.mBitsPerChannel)
			{
				audioFormat = AL_FORMAT_STEREO8;
			}
			else
			{
				audioFormat = AL_FORMAT_STEREO16;
			}
		}
		
		return [ALBuffer bufferWithName:name
								   data:streamData
								   size:bufferSize
								 format:audioFormat
							  frequency:(ALsizei)streamDescription.mSampleRate];
	}
}

+ (ALBuffer*) bufferFromUrl:(NSURL*) url reduceToMono:(bool) reduceToMono
{
	id file = [[self alloc] initWithUrl:url reduceToMono:reduceToMono];
	ALBuffer* buffer = [file bufferNamed:[url description]
							  startFrame:0
							   numFrames:-1];
	[file close];
	[file release];
	return buffer;
}

@end
