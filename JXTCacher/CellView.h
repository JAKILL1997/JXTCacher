//
//  CellView.h
//  JXTCacher
//
//  Created by wangdan on 15/8/30.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CellView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *headImgView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sexLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;



-(void)setHeadImg:(UIImage *)headImg;
-(void)setName:(NSString *)name;
-(void)setSex:(NSString *)sex;
-(void)setLocation:(NSString *)location;


@end
