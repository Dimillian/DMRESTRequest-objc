//
//  DMRESTRequest.m
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMRESTRequest.h"
#import "NSString+TotalEscaping.h"
#import <UIKit/UIKit.h>
#import "DMJSONCache.h"

@interface DMRESTRequest ()
{
    NSMutableData *_responseData;
    NSURLConnection *_connection;
    NSURLResponse *_urlResponse;
    NSError *_error;
    BOOL _success;
    long long _contentSize;
    NSUInteger _currentSize;
    BOOL _isCancelled; 
}

-(NSMutableURLRequest *)constructRequest;
-(NSURL *)getURL;
-(NSString *)constructParametersString;
-(NSData *)parametersToJSON;

@property (nonatomic, copy) DMResponseBlock responseBlock;
@property (nonatomic, copy) DMProgressBlock progressBlock;
@property (nonatomic, copy) DMConnectionErrorBlock errorBlock;
@property (nonatomic, copy) DMCompletionBlock completionBlock;
@property (nonatomic, copy) DMHTTPAuthBlock httpAuthBlock;
@property (nonatomic, copy) DMFullCompletionBlock fullCompletionBlock;
@property (nonatomic, copy) DMJSONCacheCompletionBlock jsonCacheCompletionBlock;

@property (nonatomic, readonly) DMRESTSettings *inUseSettings;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *ressource;
@property (nonatomic, strong) NSDictionary *parameters;
@end

@implementation DMRESTRequest

-(id)initWithMethod:(NSString *)method  
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters
{
    self = [super init]; 
    if (self) {
        _method = method; 
        _ressource = ressource; 
        _parameters = parameters;
        _contentSize = 0;
        _currentSize = 0;
        _isCancelled = NO;
    }
    return self; 
}

-(DMRESTSettings *)inUseSettings
{
    if (_privateCustomSettings) {
        return _privateCustomSettings;
    }
    return [DMRESTSettings sharedSettings];
}


-(NSMutableURLRequest *)constructRequest
{
    NSAssert(self.inUseSettings.baseURL, @"You must set a baseURL");
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setTimeoutInterval:self.inUseSettings.customTimemout];
    if ([_method isEqualToString:@"GET"]) {
        [request setURL:[self getURL]];
    }
    else {
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.%@",
                                              self.inUseSettings.baseURL.absoluteString,
                                              _ressource,
                                              self.inUseSettings.fileExtension]]];
        [request setHTTPMethod:_method];
        if (![self.inUseSettings isSendJSON]) {
            NSData *data = [[self constructParametersString]dataUsingEncoding:NSUTF8StringEncoding 
                                                         allowLossyConversion:YES];
            NSString *length = [NSString stringWithFormat:@"%d", [data length]];
            [request setValue:length forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:data];
        }
        else {
            NSData *jsonParameters = [self parametersToJSON];
            NSString *length = [NSString stringWithFormat:@"%d", jsonParameters.length];
            [request setValue:length forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:jsonParameters];
        }
        [self.inUseSettings.permanentHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *stringKey = (NSString *)key;
            NSString *value = (NSString *)obj;
            [request setValue:value forHTTPHeaderField:stringKey];
        }];
        
    }
    return request; 
}

-(NSURL *)getURL
{
    NSString *fileExt;
    if (self.inUseSettings.fileExtension) {
        fileExt = self.inUseSettings.fileExtension;
    }
    else{
        fileExt = @"";
    }
    return [NSURL URLWithString:
                     [NSString stringWithFormat:@"%@/%@.%@?%@",
                      self.inUseSettings.baseURL.absoluteString,
                      _ressource,
                      fileExt,
                      [self constructParametersString]]];
}

-(NSString *)constructParametersString
{
    __block NSString *parametersString = [[NSString alloc]init];
    if (_parameters) {
        [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (self.inUseSettings.isEscaping) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *string = (NSString *)obj;
                    NSString *escapedParameter = [string stringByEscapingForURLWithString:string];
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, escapedParameter];
                }
                else{
                    parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
                }
            }
            else{
                parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
            }
        }];
    } 
    if (self.inUseSettings.permanentParameters) {
        [self.inUseSettings.permanentParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            parametersString = [parametersString stringByAppendingFormat:@"%@=%@&", key, obj];
        }];
    }
    
    parametersString = [parametersString stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];
    if ([parametersString length] > 0) {
        parametersString = [parametersString substringToIndex:[parametersString length] - 1];
    }
    
    if (!_parameters && !self.inUseSettings.permanentParameters) {
         parametersString = @"";
    }
    return parametersString;
}

-(NSData *)parametersToJSON
{
    NSError *error = nil;
    __block NSMutableDictionary *finalParameters = [[NSMutableDictionary alloc]init];
    [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [finalParameters setObject:obj forKey:key];
    }];
    if (self.inUseSettings.permanentParameters) {
        [self.inUseSettings.permanentParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [finalParameters setObject:obj forKey:key];
        }];
    }
    return [NSJSONSerialization dataWithJSONObject:finalParameters
                                           options:NSJSONWritingPrettyPrinted 
                                             error:&error]; 
}

-(void)executeBlockRequest:(DMFullCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;  
    });
    [NSURLConnection sendAsynchronousRequest:[self constructRequest] 
                                       queue:[NSOperationQueue currentQueue] 
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *error){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               });
                               if (error.code == -1009 || _isCancelled) {
                                   _isCancelled  = NO;
                                   completionBlock(res, data, error, NO);
                               }
                               else{
                                   completionBlock(res, data, error, YES);
                               }
                           }];
}


-(void)executeJSONBlockRequestWithCache:(BOOL)useCache
                      JSONReadingOption:(NSJSONReadingOptions)option
                             completion:(DMJSONCacheCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    NSString *fileName = [DMJSONCache generateKeyFromURLString:[[self getURL]absoluteString]];
    if ([_method isEqualToString:@"GET"] && useCache) {
        id cachedObject = [[DMJSONCache sharedCache]cachedJSONObjectForKey:fileName];
        if (cachedObject) {
            completionBlock(nil, cachedObject, nil, YES, YES);
        }
    }
    [NSURLConnection sendAsynchronousRequest:[self constructRequest]
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *res, NSData *data, NSError *error){
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               });
                               if (error.code == -1009 || _isCancelled) {
                                   _isCancelled = NO;
                                   completionBlock(res, nil, error, NO, NO);
                               }
                               else{
                                   NSError *jsonError = nil;
                                   id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                   options:option
                                                                                     error:&jsonError];
                                   if (!error && jsonObject) {
                                       if (useCache) {
                                           [[DMJSONCache sharedCache]cacheJSONObject:jsonObject forKey:fileName];   
                                       }
                                       completionBlock(res, jsonObject, nil, YES, NO);
                                   }
                                   else{
                                       completionBlock(res, nil, jsonError, NO, NO);
                                   }
                               }
                               
                           }];

}

- (void)executeBlockRequest:(DMFullCompletionBlock)completionBlock
      requestAskforHTTPAuth:(DMHTTPAuthBlock)httpAuthBlock
{
    _fullCompletionBlock = completionBlock;
    _httpAuthBlock = httpAuthBlock;
    _responseData = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
}

- (void)executeDetailedBlockRequestReceivedResponse:(DMResponseBlock)responseBlock
                              requestAskforHTTPAuth:(DMHTTPAuthBlock)httpAuthBlock
                           progressWithReceivedData:(DMProgressBlock)progressBlock
                                    failedWithError:(DMConnectionErrorBlock)errorBlock
                                    finishedRequest:(DMCompletionBlock)completionBlock
{
    _completionBlock = completionBlock;
    _errorBlock = errorBlock;
    _responseBlock = responseBlock;
    _progressBlock = progressBlock;
    _httpAuthBlock = httpAuthBlock;
    _responseData = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
}

- (void)executeRequestWithDelegate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    _connection = [[NSURLConnection alloc] initWithRequest:[self constructRequest] delegate:self];
    if (_connection) {
        _responseData = [[NSMutableData alloc] init];
        [self.delegate requestDidStart];
    }
}

-(void)cancelRequest
{
    [_connection cancel]; 
    _connection = nil; 
    _responseData = nil; 
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
    _currentSize = 0;
    _contentSize = 0;
    _isCancelled = YES;
}


#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[_responseData setLength:0];
    _urlResponse = response;
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    if (_responseBlock) {
        _contentSize = [response expectedContentLength];
        _currentSize = 0;
        _responseBlock(response, responseStatusCode, _contentSize);
    }
    if ([self.delegate respondsToSelector:@selector(requestDidRespondWithHTTPStatus:)]) {
        [self.delegate requestDidRespondWithHTTPStatus:responseStatusCode];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
    if (_progressBlock) {
        _currentSize += [data length];
        _progressBlock(_responseData, data, _currentSize);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([error code] == -1009) {
        if ([self.delegate respondsToSelector:@selector(requestDidFailBecauseNoActiveConnection)]) {
            [self.delegate requestDidFailBecauseNoActiveConnection];
        }
    }
    if ([self.delegate respondsToSelector:@selector(requestDidFailWithError:)]) {
        [self.delegate requestDidFailWithError:error];
    }
    if (_errorBlock) {
        _errorBlock(error);
    }
    _error = error;
    _success = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
	_success = YES;
    if(_completionBlock){
        _completionBlock(_responseData);
    }
    if (_fullCompletionBlock) {
        if (_isCancelled) {
            _isCancelled = NO;
            _fullCompletionBlock(_urlResponse, _responseData, _error, NO);
        }
        else{
            _fullCompletionBlock(_urlResponse, _responseData, _error, _success);   
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(requestDidFinishWithData:)]) {
        [self.delegate requestDidFinishWithData:_responseData];
    }
    
    if ([self.delegate respondsToSelector:@selector(requestDidFinishWithJSON:)]) {
        NSError *jsonError;
        NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:_responseData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&jsonError];
        if (!jsonError && json) {
            [self.delegate requestDidFinishWithJSON:json];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
}


#pragma mark - HTTP auth


-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DMRESTHTTPAuthCredential *auth = _httpAuthBlock();
    if (auth.login && auth.password && auth.continueLogin) {
        NSURLCredential *credential = [[NSURLCredential alloc]initWithUser:auth.login
                                                                  password:auth.password
                                                               persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender]useCredential:credential forAuthenticationChallenge:challenge]; 
    }
    else if (!auth.continueLogin){
        [[challenge sender]cancelAuthenticationChallenge:challenge];
        [self cancelRequest];
        _fullCompletionBlock(_urlResponse, nil, _error, NO);
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO; 
}

@end

@interface DMRESTHTTPAuthCredential ()
@property (nonatomic, copy, readwrite) NSString *login;
@property (nonatomic, copy, readwrite) NSString *password;
@property (nonatomic, readwrite) BOOL continueLogin;
@end

@implementation DMRESTHTTPAuthCredential

- (id)initWithLogin:(NSString *)login password:(NSString *)password continueLogin:(BOOL)continueLogin
{
    self = [super init];
    if (self) {
        _login = login;
        _password = password;
        _continueLogin = continueLogin;
    }
    return self;
}

@end
