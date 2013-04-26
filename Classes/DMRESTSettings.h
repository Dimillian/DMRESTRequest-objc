//
//  DMRESTSettings.h
//  DMRestRequest
//
//  Created by Thomas Ricouard on 4/26/13.
//
//

#import <Foundation/Foundation.h>

/**
 DMRESTSettings define the settings shared between your DMRESTRequest instances
 Some properties are required some other not
 Your must set baseURL and fileExtension before executing any request
 */
@interface DMRESTSettings : NSObject

/**
 Designated singleton access to set and access the shares settings
 */
+(DMRESTSettings *)sharedSettings;

/**
 Designated initiliazer if you don't want to use shared settings
 Create an instance of this class and set it to the privateCustomSettings field of your DMRESTRequest
 It will prevent it to use the shared settings but use the passed settings instead
 */
-(id)initForPrivateSettingsWithBaseURL:(NSURL *)baseURL
                         fileExtension:(NSString *)fileExtension;

/**
 the base URL of all your request, must be set before doing a request
 */
@property (nonatomic, strong) NSURL *baseURL;
/**
 the file extension of your endpoint (.json, .xml, .php etc...)
 */
@property (nonatomic, copy) NSString *fileExtension;
/**
 The timeout the request should wait before throwing an error.
 Default value is 60 seconds (Think of Edge)
 */
@property (nonatomic) NSTimeInterval customTimemout;
/**
 Define if parameters should be converted to JSON format (or not) before executing the request
 Default is NO
 */
@property (nonatomic, getter = isSendJSON) BOOL sendJSON;
/** 
 Indicate if you want to add the GZIP header field for your requests
 Default is NO
 */
@property (nonatomic, getter = isGZIP) BOOL GZIP;
/**
 Indicate if DMRESTRequest should escape or not your parameters
 Default is NO
 */
@property (nonatomic, getter = isEscapring) BOOL escaping;
/**
 A Dictionnary you can use to totally replace defaults HTTPHeaderFields, mostly for advanced user with specific
 server configuration
 */
@property (nonatomic, strong) NSDictionary *customHTTPHeaderFields;
@end
