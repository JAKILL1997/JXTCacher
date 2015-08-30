//
//  CellView.m
//  JXTCacher
//
//  Created by wangdan on 15/8/30.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#import "CellView.h"

@implementation CellView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void)setHeadImg:(UIImage *)headImg
{
    if (headImg) {
        self.headImgView.image = headImg;
    }
}


-(void)setName:(NSString *)name
{
    if (name) {
        self.nameLabel.text = name;
    }
}

-(void)setSex:(NSString *)sex
{
    if (sex) {
        self.sexLabel.text = sex;
    }
}

-(void)setLocation:(NSString *)location
{
    if (location) {
        self.locationLabel.text = location;
    }
}
@end
