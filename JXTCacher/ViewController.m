//
//  ViewController.m
//  JXTCacher
//
//  Created by wangdan on 15/8/30.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#import "ViewController.h"
#import "ViewModel.h"
#import "JXTCacher.h"
#import "CellView.h"

#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height

@interface ViewController()<UITableViewDataSource,UITableViewDelegate>



@property (nonatomic,strong) UITableView *tbView;
@property (nonatomic,strong) NSMutableArray *dataSource;

@end

@implementation ViewController


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"cacher test";
    self.navigationController.navigationBar.translucent = NO;
    [self.view addSubview:self.tbView];
    [self loadData];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)loadData
{
    [[JXTCacher cacher] objectForKey:@"test" userId:@"2015030201" achive:^(JXTCacher *cacher, id obj, CacheError error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (obj && error == 0) {  //local or cache have data
                self.dataSource = obj;
                [self.tbView reloadData];
            }
            else { // local and cache have no data
                
                NSMutableArray *mudic = [self fixedDataArray]; //generate data
                [cacher setObject:mudic // save data to local disk and cache
                           forKey:@"test"
                           userId:@"2015030201"
                       useArchive:YES
                           setted:^(JXTCacher *cacher, CacheError error) {
                           }];
                self.dataSource = mudic;
                [self.tbView reloadData];
            }
        });
    }];
}


-(UITableView*)tbView
{
    if (!_tbView) {
        _tbView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _tbView.backgroundColor = [UIColor lightGrayColor];
        _tbView.dataSource = self;
        _tbView.delegate = self;
        
    }
    return _tbView;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifer = @"test";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.frame = CGRectMake(0, 0, SCREEN_WIDTH, 70);
        cell.clipsToBounds = YES;
    }
    
    
    CellView *view = (CellView*)[cell.contentView viewWithTag:100];
    if (view) {
        
    }
    else {
        
        NSArray *viewArray = [[NSBundle mainBundle] loadNibNamed:@"CellView" owner:nil options:nil];
        view = [viewArray firstObject];
        view.tag = 100;
        [cell.contentView addSubview:view];
    }
    
    ViewModel *model = [self.dataSource objectAtIndex:indexPath.row];
    
    if (model) {
        [view setName:model.name];
        [view setSex:model.sex];
        [view setLocation:model.location];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:model.headUrl]];
            UIImage *headImg = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                UITableViewCell*reallCell =  [tableView cellForRowAtIndexPath:indexPath];
                CellView *cellView = (CellView*) [reallCell viewWithTag:100];
                [cellView setHeadImg:headImg];
            });
        });
    }
    
    return cell;
}



-(NSMutableArray*)fixedDataArray
{
    
    ViewModel *modelFirst = [ViewModel new];
    modelFirst.name = @"柳传志";
    modelFirst.sex = @"男";
    modelFirst.location = @"北京联想公司总裁办";
    modelFirst.headUrl = @"http://d.hiphotos.baidu.com/baike/c0%3Dbaike92%2C5%2C5%2C92%2C30/sign=eeeb30aee5dde711f3df4ba4c686a57e/d01373f082025aaf9f86fe60fbedab64024f1ae0.jpg";
    
    
    
    ViewModel *modelSecond = [ViewModel new];
    modelSecond.name = @"林俊杰";
    modelSecond.sex = @"男";
    modelSecond.location = @"新加坡国际艺人联合办";
    modelSecond.headUrl = @"http://h.hiphotos.baidu.com/baike/c0%3Dbaike180%2C5%2C5%2C180%2C60/sign=769119e8aa014c080d3620f76b12696d/0df3d7ca7bcb0a466daa1f786863f6246a60afe3.jpg";
    
    
    NSMutableArray *muArray = [NSMutableArray array];
    
    for (int i=0; i<30; i++) {
        if (i%2 == 0) {
            [muArray addObject:modelFirst];
        }
        else {
            [muArray addObject:modelSecond];
        }
    }
    
    return muArray;
}

@end
