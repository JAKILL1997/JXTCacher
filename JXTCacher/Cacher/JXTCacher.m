//
//  JXTCacher.m
//  jiaoxuetong
//
//  Created by wangdan on 15/6/16.
//  Copyright (c) 2015年 wangdan. All rights reserved.
//

#import "JXTCacher.h"
#import <CommonCrypto/CommonDigest.h>




#define JXT_SIZE_OF_KEY_KEY     @"jxtobjsizekey"
#define JXT_UID_OF_KEY_KEY      @"uidofkey"
#define JXT_ARCHIVE_TYPE_OF_KEY @"archiveTypeOfKey"

#define JXTCACHE_FOLDER_PATH    NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES).lastObject


@interface JXTCacher()

@property (nonatomic,strong) dispatch_queue_t ioQueue_busy;
@property (nonatomic,strong) dispatch_queue_t ioQueue_idle;

@property (nonatomic,strong) NSMutableDictionary *sizeOfKey;

@property (nonatomic,strong) NSMutableDictionary *objOfKey;//存储经常交互的数据,  通过key索引
@property (nonatomic,strong) NSMutableDictionary *statusOfKey;//存储正在被访问的key状态

@property (nonatomic,strong) NSMutableDictionary *archiveTypeOfKey;




@end


@implementation JXTCacher

@synthesize totalSize = _totalSize;

-(id)init {
    if (self = [super init]) {
        [self initQueue];
        [self initMemorySize];
        [self initDiskPath];
        [self initMemorySize];
        [self initTemperyObj];
    }
    return self;
}

+(JXTCacher *)cacher {
    static JXTCacher *cacher;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacher = [[JXTCacher alloc] init];
    });
    return cacher;
}


#pragma  mark - 参数初始化
-(void)initQueue {
    self.ioQueue_busy = dispatch_queue_create("com.iflytek.eclass.cache.iobusy", NULL);
    self.ioQueue_idle = dispatch_queue_create("com.iflytek.eclass.cache.ioIdle", NULL);
}

-(void)initDiskPath {
    //    if (![[NSFileManager defaultManager] fileExistsAtPath:JXTCACHE_PATH isDirectory:NULL]) {
    //        [[NSFileManager defaultManager] createDirectoryAtPath:JXTCACHE_PATH withIntermediateDirectories:YES attributes:nil error:nil];
    //    }
    
}

-(void)initMemorySize {
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:JXT_SIZE_OF_KEY_KEY];
    self.sizeOfKey = [[NSMutableDictionary alloc] initWithDictionary:dic];
    if (self.sizeOfKey == nil || self.sizeOfKey.allKeys.count ==0) {
        self.totalSize = 0;
        self.sizeOfKey = [[NSMutableDictionary alloc] init];
    }
    else {
        for (NSString *key in self.sizeOfKey) {
            self.totalSize += [[self.sizeOfKey objectForKey:key] longValue];
        }
    }
    
    NSDictionary *archiveDic = [[NSUserDefaults standardUserDefaults] objectForKey:JXT_ARCHIVE_TYPE_OF_KEY];
    if (archiveDic == nil) {
        self.archiveTypeOfKey = [[NSMutableDictionary alloc] init];
    }
    else {
        self.archiveTypeOfKey = [[NSMutableDictionary alloc] initWithDictionary:archiveDic];
    }
}

-(void)initTemperyObj {
    self.statusOfKey = [[NSMutableDictionary alloc] init];
    self.objOfKey = [[NSMutableDictionary alloc] init];
}


#pragma mark - 属性 getter setter
-(void)setTotalSize:(long)totalSize {
    _totalSize = totalSize;
}




#pragma mark - 字符串处理
-(NSString *)memoryKeyOfKey:(NSString *)key userId:(NSString *)uid
{
    if (!key || !uid) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@|%@",key,uid];
    return  nil;//临时memory中的obect，需要通过key＋uid一起索引
}

-(NSString *)md5:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *fileName =
    [NSString stringWithFormat:
     @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
     r[0], r[1], r[2], r[3], r[4], r[5], r[6],
     r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return fileName;
}

-(NSString*)folderPath:(NSString *)uid {
    return [NSString stringWithFormat:@"%@/%@",JXTCACHE_FOLDER_PATH,uid];
}

-(NSString*)filePath:(NSString *)uid key:(NSString*)key {
    return [NSString stringWithFormat:@"%@/%@/%@",JXTCACHE_FOLDER_PATH,uid,[self md5:key]];
}


#pragma mark - 数据存储

//该函数已经被废弃了啊，但是考虑到有一些接口还在使用
//暂时还放在这里吧
-(void)setObject:(id)obj forKey:(NSString *)key userId:(NSString *)uid {
    if (!uid || !key || !obj) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        NSData *data = nil;
        BOOL needWriteFile = 0;
        NSString *folderPath = [self folderPath:uid];
        NSString *filePath = [self filePath:uid key:key];
        
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:nil];
            if (data == nil) {
                return ;
            }
        }
        else {
            return ;
        }
        
        NSString *keyOfUidAndKey = [self memoryKeyOfKey:key userId:uid];
        
        if (weakSelf.sizeOfKey[keyOfUidAndKey] != nil) {
            if ([weakSelf.sizeOfKey[keyOfUidAndKey] longValue] != data.length) {
                needWriteFile = YES;
                [weakSelf.objOfKey setObject:obj forKey:keyOfUidAndKey];
                weakSelf.totalSize += data.length-[weakSelf.sizeOfKey[keyOfUidAndKey] longValue];
                [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
                {
                    [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
                }
            }
            else {
                needWriteFile = NO;
            }
        }
        else {
            needWriteFile = YES;
            weakSelf.totalSize += data.length;
            [weakSelf.objOfKey setObject:obj forKey:keyOfUidAndKey];
            [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
            
            {
                [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            }
        }
        
        if (needWriteFile) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:folderPath isDirectory:NULL]) {
                [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            if (![fm fileExistsAtPath:filePath isDirectory:NULL]) {
                [fm createFileAtPath:filePath contents:nil attributes:nil];
            }
        }
        
        NSError *error = [[NSError alloc] init];
        BOOL writeResult=[data writeToFile:filePath options:NSDataWritingAtomic error:&error];
        if (writeResult == 0) {
            NSLog(@"error is %@",error.domain);
        }
        
    });//end of dispatch_async
}



-(void)setObject:(id)obj forKey:(NSString *)key userId:(NSString *)uid useArchive:(ArchiveType)needArchive
{
    if (!uid || !key || !obj) {
        return;
    }
    __weak  typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        id memoryObj = nil;
        NSMutableData *data = nil;
        if (!needArchive) {
            if (![obj isKindOfClass:[NSDictionary class]] && [obj isKindOfClass:[NSArray class]]) {
                return ;
            }
            
            NSData *middleData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:nil];
            if (!middleData) {
                return ;
            }
            data = [[NSMutableData alloc] initWithData:middleData];
            memoryObj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        else {
            NSData* middleData = [NSKeyedArchiver archivedDataWithRootObject:obj];
            if (!middleData) {
                return;
            }
            data = [[NSMutableData alloc] initWithData:middleData];
            memoryObj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        
        NSString *keyOfUidAndKey = [self memoryKeyOfKey:key userId:uid];
        BOOL needWriteFile = 0;
        NSString *folderPath = [self folderPath:uid];
        NSString *filePath = [self filePath:uid key:key];
        [self.archiveTypeOfKey setObject:[NSNumber numberWithInt:needArchive] forKey:keyOfUidAndKey];
        [self localStoreArchiveTypeOfKey:self key:JXT_ARCHIVE_TYPE_OF_KEY];
        
        if (weakSelf.sizeOfKey[keyOfUidAndKey] != nil) {
            if ([weakSelf.sizeOfKey[keyOfUidAndKey] longValue] != data.length) {
                needWriteFile = YES;
                [weakSelf.objOfKey setObject:memoryObj forKey:keyOfUidAndKey];
                weakSelf.totalSize += data.length-[weakSelf.sizeOfKey[keyOfUidAndKey] longValue];
                [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
                {
                    [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
                }
            }
            else {
                needWriteFile = NO;
            }
        }
        else {
            needWriteFile = YES;
            weakSelf.totalSize += data.length;
            [weakSelf.objOfKey setObject:memoryObj forKey:keyOfUidAndKey];
            [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
            
            {
                [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            }
        }
        
        if (needWriteFile) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:folderPath isDirectory:NULL]) {
                [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            if (![fm fileExistsAtPath:filePath isDirectory:NULL]) {
                [fm createFileAtPath:filePath contents:nil attributes:nil];
            }
        }
        
        NSError *error = [[NSError alloc] init];
        BOOL writeResult=[data writeToFile:filePath options:NSDataWritingAtomic error:&error];
        if (writeResult == 0) {
        }
        
    });//end of dispatch_async
}



-(void)setObject:(id)obj forKey:(NSString*)key userId:(NSString*)uid useArchive:(ArchiveType)needArchive setted:(JXTCacheObjSetBlock)block
{
    if (!uid || !key || !obj) {
        return;
    }
    __weak  typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        id memoryObj = nil;
        NSMutableData *data = nil;
        if (!needArchive) {
            if (![obj isKindOfClass:[NSDictionary class]] && [obj isKindOfClass:[NSArray class]]) {
                if (block) {
                    block(weakSelf,CacheErrorBadInJsonData);
                }
                return ;
            };
            NSData *middleData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:nil];
            if (!middleData) {
                if (block) {
                    block(weakSelf,CacheErrorBadInJsonData) ;
                }
                return ;
            }
            data = [[NSMutableData alloc] initWithData:middleData];
            memoryObj = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        else {
            NSData* middleData = [NSKeyedArchiver archivedDataWithRootObject:obj];
            if (!middleData) {
                if (block) {
                    block(weakSelf,CacheErrorBadArchiveData) ;
                }
                return;
            }
            data = [[NSMutableData alloc] initWithData:middleData];
            memoryObj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        
        NSString *keyOfUidAndKey = [self memoryKeyOfKey:key userId:uid];
        BOOL needWriteFile = 0;
        NSString *folderPath = [self folderPath:uid];
        NSString *filePath = [self filePath:uid key:key];
        [self.archiveTypeOfKey setObject:[NSNumber numberWithInt:needArchive] forKey:keyOfUidAndKey];
        [self localStoreArchiveTypeOfKey:self key:JXT_ARCHIVE_TYPE_OF_KEY];
        
        if (weakSelf.sizeOfKey[keyOfUidAndKey] != nil) {
            if ([weakSelf.sizeOfKey[keyOfUidAndKey] longValue] != data.length) {
                needWriteFile = YES;
                [weakSelf.objOfKey setObject:memoryObj forKey:keyOfUidAndKey];
                weakSelf.totalSize += data.length-[weakSelf.sizeOfKey[keyOfUidAndKey] longValue];
                [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
                {
                    [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
                }
            }
            else {
                needWriteFile = NO;
            }
        }
        else {
            needWriteFile = YES;
            weakSelf.totalSize += data.length;
            [weakSelf.objOfKey setObject:memoryObj forKey:keyOfUidAndKey];
            [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:data.length] forKey:keyOfUidAndKey];
            
            {
                [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            }
        }
        
        if (needWriteFile) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:folderPath isDirectory:NULL]) {
                [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            if (![fm fileExistsAtPath:filePath isDirectory:NULL]) {
                [fm createFileAtPath:filePath contents:nil attributes:nil];
            }
        }
        
        NSError *error = [[NSError alloc] init];
        BOOL writeResult=[data writeToFile:filePath options:NSDataWritingAtomic error:&error];
        if (writeResult == 0) {
            if (block) {
                block(weakSelf,CacheErrorWriteFileFailed);
            }
        }
        if (block) {
            block(weakSelf,CacheErrorNoError);
        }
        
    });//end of dispatch_async
}


-(id)objectInMemoryForKey:(NSString *)key userId:(NSString *)uid {
    if (!uid || !key) {
        return nil;
    }
    NSString *keyOfUidAndKey = [self memoryKeyOfKey:key userId:uid];
    if (self.objOfKey[keyOfUidAndKey] != nil) {
        return [self.objOfKey objectForKey:keyOfUidAndKey];
    }
    return nil;
}


-(void)objectForKey:(NSString *)key userId:(NSString *)uid achive:(JXTCacheObjGetBlock)block {
    
    if (!uid || !key || !block) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.ioQueue_busy, ^{
        NSString *keyOfUidAndKey = [weakSelf memoryKeyOfKey:key userId:uid];
        if (weakSelf.objOfKey[keyOfUidAndKey] != nil) {
            block(weakSelf,weakSelf.objOfKey[keyOfUidAndKey],CacheErrorNoError);
            return;
        }
        
        NSString *filePath = [weakSelf filePath:uid key:key];
        NSData *objData = [NSData dataWithContentsOfFile:filePath];
        
        if (objData == nil) {
            block(weakSelf,nil,CacheErrorCacheDataNotExist);
            return;
        }
        
        id obj = nil;
        BOOL archiveType = [[weakSelf.archiveTypeOfKey objectForKey:keyOfUidAndKey] intValue];
        
        if (archiveType == JXTFromJSONData) {
            @try {
                obj = [NSJSONSerialization JSONObjectWithData:objData options:kNilOptions error:nil];
            }
            @catch (NSException *exception) {
                [weakSelf clearObject:key userId:uid];
                NSLog(@"got exception when unarchive %@",exception);
                if (obj == nil) {
                    block(weakSelf,nil,CacheErrorBadUnarchiveData);
                    return ;
                }
            }
            @finally {
            }
        }
        else {
            
            @try {
                obj = [NSKeyedUnarchiver unarchiveObjectWithData:objData];
            }
            @catch (NSException *exception) {
                [weakSelf clearObject:key userId:uid];
                NSLog(@"got exception when unarchive %@",exception);
                if (obj == nil) {
                    block(weakSelf,nil,CacheErrorBadUnarchiveData);
                    return ;
                }
            }
            @finally {
            }
            
        }
        if (weakSelf.objOfKey[keyOfUidAndKey] == nil) {
            weakSelf.objOfKey[keyOfUidAndKey] = obj;
        }
        
        if (objData.length != [weakSelf.sizeOfKey[keyOfUidAndKey] longValue]) {
            [weakSelf.objOfKey setObject:obj forKey:keyOfUidAndKey];
            long oldLength = [weakSelf.sizeOfKey[keyOfUidAndKey] longValue];
            weakSelf.totalSize = weakSelf.totalSize-oldLength+objData.length;
            [weakSelf.sizeOfKey setValue:[NSNumber numberWithLong:objData.length] forKey:keyOfUidAndKey];
            {
                [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            }
        }
        block(weakSelf,obj,CacheErrorNoError);
    });
    
}

-(void)clearObject:(NSString *)key userId:(NSString *)uid {
    if (!key || !uid) {
        return;
    }
    NSString *keyOfUidAndKey = [self memoryKeyOfKey:key userId:uid];
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        
        NSString *filePath = [weakSelf filePath:uid key:key];
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm removeItemAtPath:filePath error:nil]) {
            long objSize = [weakSelf.sizeOfKey[keyOfUidAndKey] longValue];
            weakSelf.totalSize -= objSize;
            [weakSelf.sizeOfKey removeObjectForKey:keyOfUidAndKey];
            [weakSelf.objOfKey removeObjectForKey:keyOfUidAndKey];
            [weakSelf.archiveTypeOfKey removeObjectForKey:keyOfUidAndKey];
        }
        
        {
            [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            [weakSelf localStoreArchiveTypeOfKey:weakSelf key:JXT_ARCHIVE_TYPE_OF_KEY];
        }
    });
}


-(void)clearObject:(NSString*)uid {
    if (!uid) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        NSLog(@"删除某一个账号的id");
        
        for (NSString *totalKey in weakSelf.sizeOfKey.allKeys) {
            NSArray *keyArray = [totalKey componentsSeparatedByString:@"|"];
            NSString *arrayUid = keyArray[1];
            NSString *arrayKey = keyArray[0];
            
            if (arrayUid == uid) {
                NSFileManager *fm = [NSFileManager defaultManager];
                NSString *filePath = [weakSelf filePath:arrayUid key:arrayKey];
                if ([fm removeItemAtPath:filePath error:nil]) {
                    long objSize = [weakSelf.sizeOfKey[totalKey] longValue];
                    weakSelf.totalSize -= objSize;
                    [weakSelf.sizeOfKey removeObjectForKey:totalKey];
                    [weakSelf.objOfKey removeObjectForKey:totalKey];
                    [weakSelf.archiveTypeOfKey removeObjectForKey:totalKey];
                }
            }
        }
        [weakSelf localStoreArchiveTypeOfKey:weakSelf key:JXT_ARCHIVE_TYPE_OF_KEY];
        [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
    });
}


-(void)clearAllObject {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue_busy, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *key in weakSelf.sizeOfKey.allKeys) {
            NSArray *uidKeyArray = [key componentsSeparatedByString:@"|"];
            NSString *uid = uidKeyArray[1];
            NSString *fileKey = uidKeyArray[0];
            NSString *filePath = [weakSelf filePath:uid key:fileKey];
            if ([fm removeItemAtPath:filePath error:nil]) {
                long objSize = [weakSelf.sizeOfKey[key] longValue];
                weakSelf.totalSize -= objSize;
                [weakSelf.sizeOfKey removeObjectForKey:key];
                [weakSelf.objOfKey removeObjectForKey:key];
                [weakSelf.archiveTypeOfKey removeObjectForKey:key];
            }
        }
        {
            [weakSelf localStoreSizeOfKey:weakSelf key:JXT_SIZE_OF_KEY_KEY];
            [weakSelf localStoreArchiveTypeOfKey:weakSelf key:JXT_ARCHIVE_TYPE_OF_KEY];
        }
    });
}


-(void)localStoreSizeOfKey:(id)owner key:(NSString*)key {
    __weak JXTCacher* weakOwner = owner;
    [[NSUserDefaults standardUserDefaults] setObject:weakOwner.sizeOfKey forKey:key];
}


-(void)localStoreArchiveTypeOfKey:(id)owner key:(NSString*)key {
    __weak JXTCacher* weakOwner = owner;
    [[NSUserDefaults standardUserDefaults] setObject:weakOwner.archiveTypeOfKey forKey:key];
}

#pragma mark －销毁对象
-(void)dealloc {
    
}



@end
