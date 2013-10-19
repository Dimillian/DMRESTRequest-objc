//
//  DMJSONCache.m
//  DMRESTRequest
//
//  Created by Thomas Ricouard on 5/2/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

#import "DMJSONCache.h"
#import <UIKit/UIKit.h>

static NSString * const kCacheFolderName = @"DMRESTRequestCachedJSON";

@interface DMJSONCache ()

- (void)receivedMemoryWarning;
- (NSString *)filePath;
- (NSString *)fullFilePathForFilename:(NSString *)filename;
- (void)createCacheFolderIfNotExist;

@property (nonatomic, strong) NSCache *inMemoryCache;
@end

@implementation DMJSONCache

static DMJSONCache *sharedCache;

- (id)init
{
    self = [super init];
    if (self) {
        _inMemoryCache = [[NSCache alloc]init];
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(receivedMemoryWarning)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        [self createCacheFolderIfNotExist];
    }
    return self;
}

+ (DMJSONCache *)sharedCache
{
    if (sharedCache == nil) {
        sharedCache = [[DMJSONCache alloc]init];
    }
    return sharedCache;
}

- (BOOL)cacheJSONObject:(id)object forKey:(NSString *)key
{
    [self.inMemoryCache setObject:object forKey:key];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        NSOutputStream *opt = [NSOutputStream outputStreamToFileAtPath:[self fullFilePathForFilename:key] append:NO];
        [opt open];
        [NSJSONSerialization writeJSONObject:object toStream:opt options:0 error:nil];
        [opt close];
    });
    return YES;
}

- (id)cachedJSONObjectForKey:(NSString *)key
{
    if ([self.inMemoryCache objectForKey:key]) {
        return [self.inMemoryCache objectForKey:key];
    }
    else if ([self isFileExistForFilename:key]){
        NSInputStream *input = [NSInputStream inputStreamWithFileAtPath:[self fullFilePathForFilename:key]];
        [input open];
        NSError *readError = nil;
        id result = [NSJSONSerialization JSONObjectWithStream:input options:NSJSONReadingAllowFragments error:&readError];
        [input close];
        if (result && !readError) {
            [self.inMemoryCache setObject:result forKey:key];
            return result;
        }
    }
    else{
        return nil;
    }
    return nil;
}

#pragma mark - disk cache management

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    return [libraryDirectory stringByAppendingPathComponent:kCacheFolderName];
    
}

- (NSString *)fullFilePathForFilename:(NSString *)filename
{
    return [[self filePath] stringByAppendingPathComponent:filename];
}

- (BOOL)isFileExistForFilename:(NSString *)filename
{
    return [[NSFileManager defaultManager]fileExistsAtPath:[self fullFilePathForFilename:filename]];
}

- (void)createCacheFolderIfNotExist
{
    if (![[NSFileManager defaultManager]fileExistsAtPath:[self filePath]]) {
        NSError *fileError;
        [[NSFileManager defaultManager]createDirectoryAtPath:[self filePath]
                                 withIntermediateDirectories:NO
                                                  attributes:nil
                                                       error:&fileError];
    }
}

#pragma mark - memory management
- (void)receivedMemoryWarning
{
    [self.inMemoryCache removeAllObjects];
}

#pragma mark - static method

+ (NSString *)generateKeyFromURLString:(NSString *)urlString
{
    NSString *filename = [urlString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"&" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return filename;
}

+ (void)emptyDiskCache
{
    [[NSFileManager defaultManager]removeItemAtPath:[[DMJSONCache sharedCache]filePath]
                                              error:nil];
    [[DMJSONCache sharedCache]createCacheFolderIfNotExist];
}

+ (void)emptyInMemoryCache
{
    [[[DMJSONCache sharedCache]inMemoryCache]removeAllObjects];
}

+ (unsigned long long)diskCacheSize
{
    NSDictionary *fileAttributes = [[NSFileManager defaultManager]attributesOfItemAtPath:[[DMJSONCache sharedCache]filePath]
                                                                                    error:nil];
    return [fileAttributes fileSize];
}

@end
