//
//  JKCoding.h
//  runtimeTest
//
//  Created by wangdan on 15/6/24.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#ifndef runtimeTest_JKCoding_h
#define runtimeTest_JKCoding_h
#import <objc/runtime.h>
#import "NSObject+JKCoding.h"


/**
 * 在.m文件中使用下面的宏，可以代替手写归档协议方法,支持
 * 继承类，对象嵌套以及字典、数组中持有对象
 *
 * 使用步骤：
 * 1 在所有需要归档的对象的.m文件中，引入该头文件
 *
 * 2.在相应的.m文件中，加入宏定义 #define JKClass XXX
 * XXX 为当前类的类名
 *
 * 3.在需要归档的类的实现中，添加 JKCodingImplemention
 */

#define JKCodingImplemention \
- (void)encodeWithCoder:(NSCoder *)aCoder\
{\
    if ([JKClass superclass] != [NSObject class]) {\
        [super encodeWithCoder:aCoder];\
    }\
   unsigned int count = 0;\
   objc_property_t *pList = class_copyPropertyList([JKClass class], &count);\
    for (int i=0; i <count; i++) {\
        NSString *key= [NSString stringWithFormat:@"%s", property_getName(pList[i])];\
        [aCoder encodeObject:[self valueForKey:key] forKey:key];\
    }\
    free(pList);\
}\
\
- (id)initWithCoder:(NSCoder *)aDecoder\
{\
    if ([JKClass superclass] != [NSObject class]) {\
        self = [super initWithCoder:aDecoder];\
    }\
    else {\
        self = [super init];\
    }\
    unsigned int count = 0;\
    objc_property_t *pList = class_copyPropertyList([JKClass class], &count);\
    for (int i=0; i <count; i++) {\
        NSString *key= [NSString stringWithFormat:@"%s", property_getName(pList[i])];\
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key]; \
    }\
    free(pList);\
    return  self;\
}


#endif
