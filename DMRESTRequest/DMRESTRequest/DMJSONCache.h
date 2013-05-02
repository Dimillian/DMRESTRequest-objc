//
//  DMJSONCache.h
//  DMRESTRequest
//
//  Created by Thomas Ricouard on 5/2/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

//This class is USED by DMRESTRequest to manage JSON cache.
//It respond to memory warning and automatically clean in memory cache.
//It respond firt with in memory cache, if nothing in memory it respond with disk cache.
//You should not use DMJSONCache directly, you should only query static method if you want to empty cache manually
//or have some information about current cache size

#import <Foundation/Foundation.h>

@interface DMJSONCache : NSObject

+ (DMJSONCache *)sharedCache;

- (id)cachedJSONObjectForKey:(NSString *)key;
- (BOOL)cacheJSONObject:(id)object forKey:(NSString *)key;

+ (NSString *)generateKeyFromURLString:(NSString *)urlString;
//Complety remove disk cache
+ (void)emptyDiskCache;
//Completly remove in memory cache
+ (void)emptyInMemoryCache;
//Size for the cache folder
+ (int)diskCacheSize;
@end
