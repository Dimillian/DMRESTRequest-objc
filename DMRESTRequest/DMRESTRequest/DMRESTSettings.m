//
//  DMRESTSettings.m
//  DMRestRequest
//
//  Created by Thomas Ricouard on 4/26/13.
//
//

#import "DMRESTSettings.h"

static NSString * const kHeaderJson = @"application/json";
static NSString * const kUserAgent = @"User-Agent";
static NSString * const kHeaderFieldAccept = @"accept";
static NSString * const kHeaderFieldContentType = @"Content-Type";
static NSString * const kHeaderFieldAcceptEncoding = @"Accept-Encoding";
static NSString * const kDefaultHeaderValue = @"application/x-www-form-urlencoded";

@interface DMRESTSettings ()
@property (nonatomic, strong, readwrite) NSMutableDictionary *permanentHTTPHeaderFields;
@property (nonatomic, strong, readwrite) NSMutableDictionary *permanentParameters;
@end

@implementation DMRESTSettings
static DMRESTSettings *sharedSettings;

+(DMRESTSettings *)sharedSettings
{
    if (sharedSettings == nil) {
        sharedSettings = [[DMRESTSettings alloc]init];
    }
    return sharedSettings;
}

- (id)init
{
    self = [super init];
    if (self) {
        _permanentHTTPHeaderFields = [[NSMutableDictionary alloc]init];
        _fileExtension = @"";
        _sendJSON = NO;
        _escaping = NO;
        _customTimemout = 60;
        [self setPermanentHeaderFieldValue:kDefaultHeaderValue forHeaderField:kHeaderFieldContentType];
    }
    return self;
}

- (id)initForPrivateSettingsWithBaseURL:(NSURL *)baseURL
{
    self = [self init];
    if (self) {
        _baseURL = baseURL;
    }
    return self;
}

- (id)initForPrivateSettingsFromSharedSettings
{
    self = [DMRESTSettings sharedSettings];
    if (self) {
        
    }
    return self;
}

- (void)setUserAgent:(NSString *)userAgent
{
    _userAgent = userAgent;
    [self setPermanentHeaderFieldValue:userAgent forHeaderField:kUserAgent];
}

- (void)setSendJSON:(BOOL)sendJSON
{
    _sendJSON = sendJSON;
    if (sendJSON) {
        [self setPermanentHeaderFieldValue:kHeaderJson forHeaderField:kHeaderFieldContentType];
    }
    else{
        [self setPermanentHeaderFieldValue:kDefaultHeaderValue forHeaderField:kHeaderFieldContentType];
    }
}

- (NSString *)valueForPermanentHeaderField:(NSString *)header
{
    NSAssert(header, @"Header must not be null");
    return [self.permanentHTTPHeaderFields objectForKey:header];
}

- (void)setPermanentHeaderFieldValue:(NSString *)value forHeaderField:(NSString *)header
{
    NSAssert(header, @"Header must not be null");
    [self.permanentHTTPHeaderFields setValue:value forKey:header];
}

- (id)valueForPermanentParameter:(NSString *)parameter
{
    NSAssert(_permanentParameters, @"You must set at least one permanent parameter");
    NSAssert(parameter, @"Parameter must not be null");
    return [self.permanentParameters valueForKey:parameter];
}

- (void)setPermananentParameterValue:(id)value forParameter:(NSString *)parameter
{
    if (!_permanentParameters) {
        _permanentParameters = [[NSMutableDictionary alloc]init];
    }
    NSAssert(parameter, @"parameter must not be null");
    [self.permanentParameters setValue:value forKey:parameter];
}


@end
