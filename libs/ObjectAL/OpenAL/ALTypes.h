//
//  OpenAL.h
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


#pragma mark Types

/**
 * Represents a 3-dimensional point for certain ObjectAL properties.
 */
typedef struct
{
	/** The "X" coordinate */
	float x;
	/** The "Y" coordinate */
	float y;
	/** The "Z" coordinate */
	float z;
} ALPoint;

/**
 * Represents a 3-dimensional vector for certain ObjectAL properties.
 * Properties are the same as for ALPoint.
 */
typedef struct
{
	/** The "X" coordinate */
	float x;
	/** The "Y" coordinate */
	float y;
	/** The "Z" coordinate */
	float z;
} ALVector;

/**
 * Represents an orientation, consisting of an "at" vector (representing the "forward" direction),
 * and the "up" vector (representing "up" for the subject).
 */
typedef struct
{
	/** The "at" vector, representing "forward" */
	ALVector at;
	/** The "up" vector, representing "up" */
	ALVector up;
} ALOrientation;


#pragma mark -
#pragma mark Convenience Methods

/** Convenience inline for creating an ALPoint.
 *
 * @param x The X coordinate.
 * @param y The Y coordinate.
 * @param z The Z coordinate.
 * @return An ALPoint.
 */
static inline ALPoint alpoint(const float x, const float y, const float z)
{
	ALPoint point = {x, y, z};
	return point;
}

/** Convenience inline for creating an ALVector.
 *
 * @param x The X component.
 * @param y The Y component.
 * @param z The Z component.
 * @return An ALVector.
 */
static inline ALVector alvector(const float x, const float y, const float z)
{
	ALVector vector = {x, y, z};
	return vector;
}

/** Convenience inline for creating an ALOrientation.
 *
 * @param atX The X component of "at".
 * @param atY The Y component of "at".
 * @param atZ The Z component of "at".
 * @param upX The X component of "up".
 * @param upY The Y component of "up".
 * @param upZ The Z component of "up".
 * @return An ALOrientation.
 */
static inline ALOrientation alorientation(const float atX,
										  const float atY,
										  const float atZ,
										  const float upX,
										  const float upY,
										  const float upZ)
{
	ALOrientation orientation = { {atX, atY, atZ}, {upX,upY,upZ} };
	return orientation;
}
