//
//  ViewModel.h
//  JXTCacher
//
//  Created by wangdan on 15/8/30.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+JKCoding.h"

@interface ViewModel : NSObject

@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *location;
@property (nonatomic,copy) NSString *sex;
@property (nonatomic,copy) NSString *headUrl;

@end
