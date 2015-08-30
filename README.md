1.
support model archive and unarchive automatically,
which means no need to write encode or decode function for model

2.
support dictionary ->model, see in NSObject+JKCoding

3.
support quick cache model data and save data to local 
disk
which means,in ios mvc design pattern, model can be
saved in local disk when app quit,and you can get the saved data quickly form local disk


说明
1. 支持自动归档解档模型，只要在你的头文件模型里面引入
NSObject＋JKCoding.h 头文件

2.
支持将NSDictionary 转化成模型，只要在你的头文件模型里面引入
NSObject＋JKCoding.h 头文件，效率高于MJExtension

3.
支持模型的快速缓存。不管是UITableview的datasource还是其他页面的数据，引入JXTCacher.h文件后
可以通过 uid＋key将相关数据缓存到内存和本地，并可以快速存取
