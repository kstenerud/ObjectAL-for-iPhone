//
//  ALBuffer.m
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
// iOS application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALBuffer.h"
#import "ALWrapper.h"
#import "OpenALManager.h"
#import "ObjectALMacros.h"


@implementation ALBuffer


#pragma mark Object Management

+ (id) bufferWithName:(NSString*) name data:(void*) data size:(ALsizei) size format:(ALenum) format frequency:(ALsizei) frequency
{
	return [[[self alloc] initWithName:name data:data size:size format:format frequency:frequency] autorelease];
}

- (id) initWithName:(NSString*) nameIn data:(void*) data size:(ALsizei) size format:(ALenum) formatIn frequency:(ALsizei) frequency
{
	if(nil != (self = [super init]))
	{
		OAL_LOG_DEBUG(@"%@: Init", self);
		self.name = nameIn;
		bufferId = [ALWrapper genBuffer];
		if(nil == [OpenALManager sharedInstance].currentContext)
		{
			OAL_LOG_ERROR(@"Cannot allocate a buffer without a current context. Make sure [OpenALManager sharedInstance].currentContext is valid");
			[self release];
			return nil;
		}
		device = [[OpenALManager sharedInstance].currentContext.device retain];
		bufferData = data;
		format = formatIn;
		freeDataOnDestroy = YES;
		parentBuffer = nil;

		[ALWrapper bufferDataStatic:bufferId format:format data:bufferData size:size frequency:frequency];
		
		duration = (float)self.size / ((float)(self.frequency * self.channels * self.bits) / 8);
	}
	return self;
}

- (void) dealloc
{
	OAL_LOG_DEBUG(@"%@: Dealloc", self);
	[ALWrapper deleteBuffer:bufferId];
	[device release];
	[name release];
	[parentBuffer release];
	if(freeDataOnDestroy)
	{
		free(bufferData);
	}

	[super dealloc];
}

- (NSString*) description
{
	NSString* nameStr = NSNotFound == [name rangeOfString:@"://"].location ? name : [name lastPathComponent];
	return [NSString stringWithFormat:@"<%@: %p: %@>", [self class], self, nameStr];
}

#pragma mark Properties

- (ALuint) bits
{
	return [ALWrapper getBufferi:bufferId parameter:AL_BITS];	
}

@synthesize bufferId;

- (ALuint) channels
{
	return [ALWrapper getBufferi:bufferId parameter:AL_CHANNELS];	
}

@synthesize device;

@synthesize format;

- (ALuint) frequency
{
	return [ALWrapper getBufferi:bufferId parameter:AL_FREQUENCY];	
}

@synthesize name;

- (ALuint) size
{
	return [ALWrapper getBufferi:bufferId parameter:AL_SIZE];	
}

@synthesize duration;

@synthesize freeDataOnDestroy;

#pragma mark Buffer slicing

- (ALBuffer*)sliceWithName:(NSString *) sliceName offset:(ALsizei) offset size:(ALsizei) size {
	int frameSize = self.channels * self.bits / 8;
	int byteOffset = offset * frameSize;
	int byteSize = size * frameSize;

	if (offset < 0)
	{
		OAL_LOG_ERROR(@"%@: Buffer offset %d is too small. Returning nil", self, offset);
		return nil;
	}

	if (size < 1)
	{
		OAL_LOG_ERROR(@"%@: Buffer size %d is too small. Returning nil", self, size);
		return nil;
	}

	if (byteOffset + byteSize > (ALsizei)self.size)
	{
		OAL_LOG_ERROR(@"%@: Buffer offset+size goes beyond end of buffer (%d + %d > %d). Returning nil", self, offset, size, self.size / frameSize);
		return nil;
	}

	ALBuffer * slice = [ALBuffer bufferWithName:sliceName data:(void*)(byteOffset + (char*)bufferData) size:byteSize
										 format:self.format frequency:self.frequency];
	slice.freeDataOnDestroy = NO;
	slice->parentBuffer = [self retain];
	return slice;
}

@end
