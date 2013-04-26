//
//  DMRESTSettings.m
//  DMRestRequest
//
//  Created by Thomas Ricouard on 4/26/13.
//
//

#import "DMRESTSettings.h"

@implementation DMRESTSettings
static DMRESTSettings *sharedSettings;

+(DMRESTSettings *)sharedSettings
{
    if (sharedSettings == nil) {
        sharedSettings = [[DMRESTSettings alloc]init];
        sharedSettings.customHTTPHeaderFields = nil;
        sharedSettings.sendJSON = NO;
        sharedSettings.GZIP = NO;
        sharedSettings.escaping = NO;
        sharedSettings.customTimemout = 60;
    }
    return sharedSettings;
}

- (id)initForPrivateSettingsWithBaseURL:(NSURL *)baseURL fileExtension:(NSString *)fileExtension
{
    self = [super init];
    if (self) {
        _baseURL = baseURL;
        _fileExtension = fileExtension;
        _customHTTPHeaderFields = nil;
        _sendJSON = NO;
        _GZIP = NO,
        _escaping = NO;
        _customTimemout = 60;
    }
    return self;
}


@end
