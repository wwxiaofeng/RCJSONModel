//
//  JSONModel.h
//
//  @version 1.0.2
//  @author Marin Todorov, http://www.touch-code-magazine.com
//

// Copyright (c) 2012-2014 Marin Todorov, Underplot ltd.
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// The MIT License in plain English: http://www.touch-code-magazine.com/JSONModel/MITLicense

#import <Foundation/Foundation.h>

#import "JSONModelError.h"
#import "JSONValueTransformer.h"

#if TARGET_IPHONE_SIMULATOR
#define JMLog( s, ... ) NSLog( @"[%@:%d] %@", [[NSString stringWithUTF8String:__FILE__] \
lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define JMLog( s, ... )
#endif

@protocol Optional
@end

@protocol ConvertOnDemand
@end

@interface JSONModel : NSObject

//@property (copy) void (^completionBlock)();

- (id)initWithCompletionBlock:(void (^)(void))completionBlock;

- (id)initWithString:(NSString*)string error:(JSONModelError**)err;

- (id)initWithString:(NSString *)string
       usingEncoding:(NSStringEncoding)encoding
               error:(JSONModelError**)err;

- (id)initWithData:(NSData *)data error:(NSError **)error;

- (id)initWithDictionary:(NSDictionary*)dict error:(NSError **)err;

- (void)addMappingWithPropertyName:(NSString*)propertyName jsonKey:(NSString*)key;

- (NSDictionary*)toDictionary;

- (NSString*)toJSONString;

+ (NSMutableArray*)arrayOfModelsFromDictionaries:(NSArray*)array;

+ (NSMutableArray*)arrayOfModelsFromDictionaries:(NSArray*)array error:(NSError**)err;

+ (NSMutableArray*)arrayOfModelsFromData:(NSData*)data error:(NSError**)err;

@end
