//
//  JSONModel.m
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

#import "JSONModel.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSArray* _allowedJsonTypes = nil;
static JSONValueTransformer* valueTransformer = nil;


@implementation JSONModel
{
    NSMutableDictionary* _properyNameAndJsonKeyMapping;
}

+ (void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // initialize all class static objects,
        // which are common for ALL JSONModel subclasses
        _allowedJsonTypes = @[
                              [NSString class],
                              [NSNumber class],
                              [NSDecimalNumber class],
                              [NSArray class],
                              [NSDictionary class],
                              [NSNull class],
                              [NSMutableString class],
                              [NSMutableArray class],
                              [NSMutableDictionary class],
                              ];
        
        valueTransformer = [[JSONValueTransformer alloc] init];
      
    });
}

- (id)initWithCompletionBlock:(void (^)(void))completionBlock
{
    self = [super init];
    
    if (self) {
        return self;
    }
    return nil;
}

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)err
{
    //check for nil input
    if (!data) {
        if (err) *err = [JSONModelError errorInputIsNil];
        return nil;
    }
    //read the json
    JSONModelError* initError = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:kNilOptions
                                               error:&initError];
    
    if (initError) {
        if (err) *err = [JSONModelError errorBadJSON];
        return nil;
    }
    
    //init with dictionary
    id objModel = [self initWithDictionary:obj error:&initError];
    if (initError && err) *err = initError;
    return objModel;
}

- (id)initWithString:(NSString*)string error:(JSONModelError**)err
{
    JSONModelError* initError = nil;
    id objModel = [self initWithString:string usingEncoding:NSUTF8StringEncoding error:&initError];
    if (initError && err) *err = initError;
    return objModel;
}

- (id)initWithString:(NSString *)string usingEncoding:(NSStringEncoding)encoding error:(JSONModelError**)err
{
    //check for nil input
    if (!string) {
        if (err) *err = [JSONModelError errorInputIsNil];
        return nil;
    }
    
    JSONModelError* initError = nil;
    id objModel = [self initWithData:[string dataUsingEncoding:encoding] error:&initError];
    if (initError && err) *err = initError;
    return objModel;
    
}

- (id)initWithDictionary:(NSDictionary*)dict error:(NSError **)err;
{
    //check for nil input
    if (!dict) {
        
        if (err) {
            *err = [JSONModelError errorInputIsNil];
        }
        
        return nil;
    }
    
    //invalid input, just create empty instance
    if (![dict isKindOfClass:[NSDictionary class]]) {
        
        if (err) {
            *err = [JSONModelError errorInvalidDataWithMessage:@"Attempt to initialize JSONModel object using initWithDictionary:error: but the dictionary parameter was not an 'NSDictionary'."];
        }
        
        return nil;
    }
    
    self = [self init];
    if (!self) {
        
        //super init didn't succeed
        if (err) *err = [JSONModelError errorModelIsInvalid];
        return nil;
    }
    

    unsigned int properyListCount = 0;
    objc_property_t* properties = class_copyPropertyList([self class], &properyListCount);
    
    for (int i = 0; i < properyListCount; i++) {
        
        objc_property_t property = properties[i];
        
        NSString* propertyAttributes = @(property_getAttributes(property));
        NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        
        //ignore read-only properties
        if ([attributeItems containsObject:@"R"]) {
            continue; //to next property
        }
        
        //check for 64b BOOLs
        if ([propertyAttributes hasPrefix:@"Tc,"]) {
            //mask BOOLs as structs so they can have custom convertors
            //p.structName = @"BOOL";
        }
        
        NSString* propertyName = @(property_getName(property));
        NSString* jsonKey = [self getJsonKeyWithProperyName:propertyName];
        
       
        id jsonValue = [dict objectForKey:jsonKey];
        id propertyValue = jsonValue;
        
        if (![self isAllowedClass:[jsonValue class]]) {
            continue;
        }
        
        Class propertyClass = [self getPropertyClassWithAttributes:propertyAttributes];
        Class sourceClass = [JSONValueTransformer classByResolvingClusterClasses:[jsonValue class]];
        
        if ([jsonValue isKindOfClass:[NSDictionary class]]) {
            
            if ([propertyClass isSubclassOfClass:[JSONModel class]]) {
                propertyValue = [[propertyClass alloc] initWithDictionary:jsonValue error:nil];
            }
        }
        else if ([jsonValue isKindOfClass:[NSArray class]]) {
            
            Class protocolClass = [self getProtcolNameClassWithAttributes:propertyAttributes];
//            
//            NSMutableArray* propertyArray = [[NSMutableArray alloc] init];
//            
//            if ([protocolNameClass isSubclassOfClass:[JSONModel class]]) {
//                
//                for (int i = 0; i < [(NSArray*)jsonValue count]; i++) {
//                    
//                    NSDictionary *objectDic = [(NSArray*)jsonValue objectAtIndex:i];
//                    
//                    JSONModel* protocolObj = [[protocolNameClass alloc] initWithDictionary:objectDic error:nil];
//                    [propertyArray addObject:protocolObj];
//                }
//                
//                propertyValue = propertyArray;
//            }
            
            propertyValue = [[JSONModelArray alloc] initWithArray:jsonValue modelClass:[protocolClass class]];
            
//            NSArray* array = (NSArray*)propertyValue;
//            
//            [self setValue:array forKey:jsonKey];
            
        }
        else if (![jsonValue isKindOfClass:propertyClass]) {
            
            NSString* selectorName = [NSString stringWithFormat:@"%@From%@:",
                                      propertyClass, //target name
                                      sourceClass]; //source name
            SEL selector = NSSelectorFromString(selectorName);
            
            if ([valueTransformer respondsToSelector:selector]) {
                
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                propertyValue = [valueTransformer performSelector:selector withObject:jsonValue];
#pragma clang diagnostic pop
            }
        }
        
        if (!propertyValue || ![propertyValue isEqual:[self valueForKey:propertyName]]) {
            [self setValue:propertyValue forKey:propertyName];
        }
    }

    free(properties);
    
    return self;
}

- (BOOL)isAllowedClass:(Class)class
{
    if (class == nil) {
        return NO;
    }
    
    for (Class allowdClass in _allowedJsonTypes) {
        
        if ([class isSubclassOfClass:allowdClass]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)addMappingWithPropertyName:(NSString*)propertyName jsonKey:(NSString*)key
{
    if (!_properyNameAndJsonKeyMapping) {
        _properyNameAndJsonKeyMapping = [[NSMutableDictionary alloc] init];
    }
    
    [_properyNameAndJsonKeyMapping setObject:key forKey:propertyName];
}

- (NSString*)getJsonKeyWithProperyName:(NSString*)name
{
    NSString* jsonKey = [_properyNameAndJsonKeyMapping objectForKey:name];
    
    if (!jsonKey) {
        jsonKey = name;
    }
    
    return jsonKey;
}

- (Class)getPropertyClassWithAttributes:(NSString*)propertyAttributes
{
    NSString* propertyClass = nil;
    NSScanner*scanner = [NSScanner scannerWithString:propertyAttributes];
    [scanner scanUpToString:@"T" intoString: nil];
    [scanner scanString:@"T" intoString:nil];
    
    if ([scanner scanString:@"@\"" intoString: &propertyClass]) {
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                intoString:&propertyClass];
    }
    
    return NSClassFromString(propertyClass);
}

- (Class)getProtcolNameClassWithAttributes:(NSString*)propertyAttributes
{
    NSString* protocolNameClass = nil;
    
    NSScanner*scanner = [NSScanner scannerWithString:propertyAttributes];
    [scanner scanUpToString:@"T" intoString: nil];
    [scanner scanString:@"T" intoString:nil];
    
    if ([scanner scanString:@"@\"" intoString: NULL]) {
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                intoString:NULL];
        
        while ([scanner scanString:@"<" intoString:NULL]) {
            [scanner scanUpToString:@">" intoString: &protocolNameClass];
            [scanner scanString:@">" intoString:NULL];
        }
        
    }
    
    return NSClassFromString(protocolNameClass);
}

- (NSDictionary*)toDictionary
{
    return [self toDictionaryWithKeys:nil];
}

- (NSString*)toJSONString
{
    return [self toJSONStringWithKeys:nil];
}

- (NSDictionary*)toDictionaryWithKeys:(NSArray*)propertyNames
{
    return nil;
}

- (NSString*)toJSONStringWithKeys:(NSArray*)propertyNames
{
    return nil;
}

@end

