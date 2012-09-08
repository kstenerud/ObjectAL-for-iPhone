/* Copyright (c) 2007 Scott Lembcke
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "CCArray.h"

/** Allocates and initializes a new array with specified capacity */
ccArray* ccArrayNew(NSUInteger capacity) {
	if (capacity == 0)
		capacity = 1;
	
	ccArray *arr = (ccArray*)malloc( sizeof(ccArray) );
	arr->num = 0;
	arr->arr =  (CCARRAY_ID *)calloc(capacity, sizeof(id));
	arr->max = capacity;
	
	return arr;
}

/** Frees array after removing all remaining objects. Silently ignores nil arr. */
void ccArrayFree(ccArray *arr)
{
	if( arr == nil ) return;
	
	ccArrayRemoveAllObjects(arr);
	
	free(arr->arr);
	free(arr);
}

void ccArrayDoubleCapacity(ccArray *arr)
{
	arr->max *= 2;
	CCARRAY_ID *newArr = (CCARRAY_ID *)realloc( arr->arr, arr->max * sizeof(id) );
	// will fail when there's not enough memory
    NSCAssert(newArr != NULL, @"ccArrayDoubleCapacity failed. Not enough memory");
	arr->arr = newArr;
}

void ccArrayEnsureExtraCapacity(ccArray *arr, NSUInteger extra)
{
	while (arr->max < arr->num + extra)
		ccArrayDoubleCapacity(arr);
}

void ccArrayShrink(ccArray *arr)
{
    NSUInteger newSize;
	
	//only resize when necessary
	if (arr->max > arr->num && !(arr->num==0 && arr->max==1))
	{
		if (arr->num!=0)
		{
			newSize=arr->num;
			arr->max=arr->num;
		}
		else
		{//minimum capacity of 1, with 0 elements the array would be free'd by realloc
			newSize=1;
			arr->max=1;
		}
		
		arr->arr = (CCARRAY_ID *) realloc(arr->arr,newSize * sizeof(id) );
		NSCAssert(arr->arr!=NULL,@"could not reallocate the memory");
	}
}

/** Returns index of first occurence of object, NSNotFound if object not found. */
NSUInteger ccArrayGetIndexOfObject(ccArray *arr, id object)
{
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++)
		if( arr->arr[i] == object ) return i;
	
	return NSNotFound;
}

/** Returns a Boolean value that indicates whether object is present in array. */
BOOL ccArrayContainsObject(ccArray *arr, id object)
{
	return ccArrayGetIndexOfObject(arr, object) != NSNotFound;
}

/** Appends an object. Bahaviour undefined if array doesn't have enough capacity. */
void ccArrayAppendObject(ccArray *arr, id object)
{
	arr->arr[arr->num] = CC_ARC_RETAIN(object);
	arr->num++;
}

/** Appends an object. Capacity of arr is increased if needed. */
void ccArrayAppendObjectWithResize(ccArray *arr, id object)
{
	ccArrayEnsureExtraCapacity(arr, 1);
	ccArrayAppendObject(arr, object);
}

/** Appends objects from plusArr to arr. Behaviour undefined if arr doesn't have
 enough capacity. */
void ccArrayAppendArray(ccArray *arr, ccArray *plusArr)
{
	NSUInteger i;
	
	for( i = 0; i < plusArr->num; i++)
		ccArrayAppendObject(arr, plusArr->arr[i]);
}

/** Appends objects from plusArr to arr. Capacity of arr is increased if needed. */
void ccArrayAppendArrayWithResize(ccArray *arr, ccArray *plusArr)
{
	ccArrayEnsureExtraCapacity(arr, plusArr->num);
	ccArrayAppendArray(arr, plusArr);
}

/** Inserts an object at index */
void ccArrayInsertObjectAtIndex(ccArray *arr, id object, NSUInteger index)
{
	NSCAssert(index<=arr->num, @"Invalid index. Out of bounds");
	
	ccArrayEnsureExtraCapacity(arr, 1);
	
	NSUInteger remaining = arr->num - index;
	if( remaining > 0)
		memmove((void *)&arr->arr[index+1], (void *)&arr->arr[index], sizeof(id) * remaining );
	
	arr->arr[index] = CC_ARC_RETAIN(object);
	arr->num++;
}

/** Swaps two objects */
void ccArraySwapObjectsAtIndexes(ccArray *arr, NSUInteger index1, NSUInteger index2)
{
	NSCAssert(index1 < arr->num, @"(1) Invalid index. Out of bounds");
	NSCAssert(index2 < arr->num, @"(2) Invalid index. Out of bounds");
	
	id object1 = arr->arr[index1];
	
	arr->arr[index1] = arr->arr[index2];
	arr->arr[index2] = object1;
}

/** Removes all objects from arr */
void ccArrayRemoveAllObjects(ccArray *arr)
{
	while( arr->num > 0 )
		CC_ARC_RELEASE(arr->arr[--arr->num]);
}

/** Removes object at specified index and pushes back all subsequent objects.
 Behaviour undefined if index outside [0, num-1]. */
void ccArrayRemoveObjectAtIndex(ccArray *arr, NSUInteger index)
{
	CC_ARC_RELEASE(arr->arr[index]);
	arr->num--;
	
	NSUInteger remaining = arr->num - index;
	if(remaining>0)
		memmove((void *)&arr->arr[index], (void *)&arr->arr[index+1], remaining * sizeof(id));
}

/** Removes object at specified index and fills the gap with the last object,
 thereby avoiding the need to push back subsequent objects.
 Behaviour undefined if index outside [0, num-1]. */
void ccArrayFastRemoveObjectAtIndex(ccArray *arr, NSUInteger index)
{
	CC_ARC_RELEASE(arr->arr[index]);
	NSUInteger last = --arr->num;
	arr->arr[index] = arr->arr[last];
}

void ccArrayFastRemoveObject(ccArray *arr, id object)
{
	NSUInteger index = ccArrayGetIndexOfObject(arr, object);
	if (index != NSNotFound)
		ccArrayFastRemoveObjectAtIndex(arr, index);
}

/** Searches for the first occurance of object and removes it. If object is not
 found the function has no effect. */
void ccArrayRemoveObject(ccArray *arr, id object)
{
	NSUInteger index = ccArrayGetIndexOfObject(arr, object);
	if (index != NSNotFound)
		ccArrayRemoveObjectAtIndex(arr, index);
}

/** Removes from arr all objects in minusArr. For each object in minusArr, the
 first matching instance in arr will be removed. */
void ccArrayRemoveArray(ccArray *arr, ccArray *minusArr)
{
	NSUInteger i;
	
	for( i = 0; i < minusArr->num; i++)
		ccArrayRemoveObject(arr, minusArr->arr[i]);
}

/** Removes from arr all objects in minusArr. For each object in minusArr, all
 matching instances in arr will be removed. */
void ccArrayFullRemoveArray(ccArray *arr, ccArray *minusArr)
{
	NSUInteger back = 0;
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++) {
		if( ccArrayContainsObject(minusArr, arr->arr[i]) ) {
			CC_ARC_RELEASE(arr->arr[i]);
			back++;
		} else
			arr->arr[i - back] = arr->arr[i];
	}
	
	arr->num -= back;
}

/** Sends to each object in arr the message identified by given selector. */
void ccArrayMakeObjectsPerformSelector(ccArray *arr, SEL sel)
{
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++)
#pragma clang diagnostic push
#if defined(__has_feature) && __has_feature(objc_arc)				
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#endif		
		[arr->arr[i] performSelector:sel];
#pragma clang diagnostic pop
}

void ccArrayMakeObjectsPerformSelectorWithObject(ccArray *arr, SEL sel, id object)
{
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++)
#pragma clang diagnostic push
		
#if defined(__has_feature) && __has_feature(objc_arc)		
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#endif		
		[arr->arr[i] performSelector:sel withObject:object];
#pragma clang diagnostic pop
}

void ccArrayMakeObjectPerformSelectorWithArrayObjects(ccArray *arr, SEL sel, id object)
{
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++)
#pragma clang diagnostic push
		
#if defined(__has_feature) && __has_feature(objc_arc)		
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#endif		
		[object performSelector:sel withObject:arr->arr[i]];
#pragma clang diagnostic pop
}


#pragma mark -
#pragma mark ccCArray for Values (c structures)

/** Allocates and initializes a new C array with specified capacity */
ccCArray* ccCArrayNew(NSUInteger capacity)
{
	if (capacity == 0)
		capacity = 1;
	
	ccCArray *arr = (ccCArray*)malloc( sizeof(ccCArray) );
	arr->num = 0;
	arr->arr =  (CCARRAY_ID *) malloc( capacity * sizeof(id) );
	arr->max = capacity;
	
	return arr;
}

/** Frees C array after removing all remaining values. Silently ignores nil arr. */
void ccCArrayFree(ccCArray *arr)
{
	if( arr == nil ) return;
	
	ccCArrayRemoveAllValues(arr);
	
	free(arr->arr);
	free(arr);
}

/** Doubles C array capacity */
void ccCArrayDoubleCapacity(ccCArray *arr)
{
	ccArrayDoubleCapacity(arr);
}

/** Increases array capacity such that max >= num + extra. */
void ccCArrayEnsureExtraCapacity(ccCArray *arr, NSUInteger extra)
{
	ccArrayEnsureExtraCapacity(arr,extra);
}

/** Returns index of first occurence of value, NSNotFound if value not found. */
NSUInteger ccCArrayGetIndexOfValue(ccCArray *arr, CCARRAY_ID value)
{
	NSUInteger i;
	
	for( i = 0; i < arr->num; i++)
		if( [arr->arr[i] isEqual:value] ) return i;
	return NSNotFound;
}

/** Returns a Boolean value that indicates whether value is present in the C array. */
BOOL ccCArrayContainsValue(ccCArray *arr, CCARRAY_ID value)
{
	return ccCArrayGetIndexOfValue(arr, value) != NSNotFound;
}

/** Inserts a value at a certain position. Behaviour undefined if aray doesn't have enough capacity */
void ccCArrayInsertValueAtIndex( ccCArray *arr, CCARRAY_ID value, NSUInteger index)
{
	NSCAssert( index < arr->max, @"ccCArrayInsertValueAtIndex: invalid index");
	
	NSUInteger remaining = arr->num - index;
	
	// last Value doesn't need to be moved
	if( remaining > 0) {
		// tex coordinates
		memmove((void *)&arr->arr[index+1], (void *)&arr->arr[index], sizeof(void*) * remaining );
	}
	
	arr->num++;
	arr->arr[index] = value;
}

/** Appends an value. Bahaviour undefined if array doesn't have enough capacity. */
void ccCArrayAppendValue(ccCArray *arr, CCARRAY_ID value)
{
	arr->arr[arr->num] = (id) value;
	arr->num++;
}

/** Appends an value. Capacity of arr is increased if needed. */
void ccCArrayAppendValueWithResize(ccCArray *arr, CCARRAY_ID value)
{
	ccCArrayEnsureExtraCapacity(arr, 1);
	ccCArrayAppendValue(arr, value);
}


/** Appends values from plusArr to arr. Behaviour undefined if arr doesn't have
 enough capacity. */
void ccCArrayAppendArray(ccCArray *arr, ccCArray *plusArr)
{
	NSUInteger i;
	
	for( i = 0; i < plusArr->num; i++)
		ccCArrayAppendValue(arr, plusArr->arr[i]);
}

/** Appends values from plusArr to arr. Capacity of arr is increased if needed. */
void ccCArrayAppendArrayWithResize(ccCArray *arr, ccCArray *plusArr)
{
	ccCArrayEnsureExtraCapacity(arr, plusArr->num);
	ccCArrayAppendArray(arr, plusArr);
}

/** Removes all values from arr */
void ccCArrayRemoveAllValues(ccCArray *arr)
{
	arr->num = 0;
}

/** Removes value at specified index and pushes back all subsequent values.
 Behaviour undefined if index outside [0, num-1].
 @since v0.99.4
 */
void ccCArrayRemoveValueAtIndex(ccCArray *arr, NSUInteger index)
{
	NSUInteger last;
	
	for( last = --arr->num; index < last; index++)
		arr->arr[index] = arr->arr[index + 1];
}

/** Removes value at specified index and fills the gap with the last value,
 thereby avoiding the need to push back subsequent values.
 Behaviour undefined if index outside [0, num-1].
 @since v0.99.4
 */
void ccCArrayFastRemoveValueAtIndex(ccCArray *arr, NSUInteger index)
{
	NSUInteger last = --arr->num;
	arr->arr[index] = arr->arr[last];
}

/** Searches for the first occurance of value and removes it. If value is not found the function has no effect.
 @since v0.99.4
 */
void ccCArrayRemoveValue(ccCArray *arr, CCARRAY_ID value)
{
	NSUInteger index = ccCArrayGetIndexOfValue(arr, value);
	if (index != NSNotFound)
		ccCArrayRemoveValueAtIndex(arr, index);
}

/** Removes from arr all values in minusArr. For each Value in minusArr, the first matching instance in arr will be removed.
 @since v0.99.4
 */
void ccCArrayRemoveArray(ccCArray *arr, ccCArray *minusArr)
{
	NSUInteger i;
	
	for( i = 0; i < minusArr->num; i++)
		ccCArrayRemoveValue(arr, minusArr->arr[i]);
}

/** Removes from arr all values in minusArr. For each value in minusArr, all matching instances in arr will be removed.
 @since v0.99.4
 */
void ccCArrayFullRemoveArray(ccCArray *arr, ccCArray *minusArr)
{
	NSUInteger i;
	NSUInteger back = 0;
	
	for( i = 0; i < arr->num; i++) {
		if( ccCArrayContainsValue(minusArr, arr->arr[i]) ) {
			back++;
		} else
			arr->arr[i - back] = arr->arr[i];
	}
	
	arr->num -= back;
}

//used by mergesortL
void cc_pointerswap(void* a, void* b, size_t width)
{
    void* tmp;
    tmp = *(void**)a;
    *(void**)a = *(void**)b;
    *(void**)b = tmp;
}

// iterative mergesort arrd on
//  http://www.inf.fh-flensburg.de/lang/algorithmen/sortieren/merge/mergiter.htm  
int cc_mergesortL(ccCArray* array, size_t width, cc_comparator comparator)
{
    CCARRAY_ID *arr = array->arr; 
    NSInteger i,j,k,s,m,n= array->num; 
    
    CCARRAY_ID *B = (CCARRAY_ID*) malloc((n/2 + 1) * width);
    for (s = 1; s < n; s += s) 
    {
        for (m = n-1-s; m >= 0; m -= s+s)
        {
            NSInteger lo = MAX(m-(s+1),0); 
            NSInteger hi = m+s; 
            
            j = lo;
			
            if (m-j > 0)
            {
                //triggers a warning when compiled with ARC, B needs to be strong typed, for compiling for obj-c++
                //memcpy aritmetics aren't allowed on void* types
                //explicitely casting didn't work
#pragma clang diagnostic push
#if defined(__has_feature) && __has_feature(objc_arc)				
#pragma clang diagnostic ignored "-Warc-non-pod-memaccess"
#endif				
                
                memcpy(B, &arr[j], (m-j) * width);
#pragma clang diagnostic pop
            }
            
            i = 0;
            j = m;
            k = lo; 
            
            while (k<j  && j <= hi) 
            {
                if (comparator(&B[i],&arr[j]) <= 0)
                {    
                    cc_pointerswap(&arr[k++],&B[i++], width);
                }
				
                else 
                {    
					cc_pointerswap(&arr[k++],&arr[j++], width);
                }
            }
            
            while (k<j)
                cc_pointerswap(&arr[k++],&B[i++],width);
        }
    }
   	free(B);
	return 0;
}

void cc_insertionSort(ccCArray* arr, cc_comparator comparator)
{
    // It sorts source array in ascending order
	
	// adaptive - performance adapts to the initial order of elements
	// stable - insertion sort retains relative order of the same elements
	// in-place - requires constant amount of additional space
	// online - new elements can be added during the sort
	
	NSInteger i,j,length = arr->num;
	
	CCARRAY_ID *x = arr->arr;
	id temp;	
    
	// insertion sort
	for(i=1; i<length; i++)
	{
		j = i;
		//continue moving element downwards while order is descending 
		while( j>0 && ( comparator(  &x[j-1],  &x[j]  ) == NSOrderedDescending) )
		{
			temp = x[j];
			x[j] = x[j-1];
			x[j-1] = temp;
			j--;
		}
	}
}
