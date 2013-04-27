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
 Initiliazer if you don't want to use shared settings
 Create an instance of this class and set it to the privateCustomSettings field of your DMRESTRequest
 It will prevent it to use the shared settings but use the passed settings instead
 Will not copy current shared settings
 */
-(id)initForPrivateSettingsWithBaseURL:(NSURL *)baseURL
                         fileExtension:(NSString *)fileExtension;
/**
 Initiliazer if you want to create private settings for a specific DMRESTRequest
 Will copy current shared settings
 */
-(id)initForPrivateSettingsFromSharedSettings;

/**
 the base URL of all your request, must be set before doing a request
 */
@property (nonatomic, strong) NSURL *baseURL;
/**
 the file extension of your endpoint (.json, .xml, .php etc...)
 */
@property (nonatomic, copy) NSString *fileExtension;

/**
 The user agent to use for your DMRESTRequest
 If nil the default user agent is used
 The user agent is added to your HTTP header field and merged with your other custom fields
 If you set it to nil the default uset agant is set
 */
@property (nonatomic, copy) NSString *userAgent;

/**
 The timeout the request should wait before throwing an error.
 Default value is 60 seconds (Think of Edge)
 */
@property (nonatomic) NSTimeInterval customTimemout;
/**
 Define if parameters should be converted to JSON format (or not) before executing the request
 Ignored for GET request, parameters will be added in the URL
 Add the JSON header field, will be merged with your other permanent header field.
 Default is NO
 */
@property (nonatomic, getter = isSendJSON) BOOL sendJSON;

/**
 Indicate if DMRESTRequest should escape or not your parameters
 Default is NO
 */
@property (nonatomic, getter = isEscaping) BOOL escaping;

@property (nonatomic, strong, readonly) NSMutableDictionary *permanentHTTPHeaderFields;
@property (nonatomic, strong, readonly) NSMutableDictionary *permanentParameters;

/**
 @return The value of the passed header field, nil if no header value set for the passed header
 */
- (NSString *)valueForPermanentHeaderField:(NSString *)header;
/**
 Set the value for the passed header field
 Header fields will be used to every request you make with shared settings
 @param value The value, the header field will be removed if the value passed is nil
 @param header The header field of the value
 */
- (void)setPermanentHeaderFieldValue:(NSString *)value forHeaderField:(NSString *)header;
/**
 @return The value of the passed paramener, nil if no paramener value set for the passed parameter
 */
- (id)valueForPermanentParameter:(NSString *)parameter;
/**
 Set the value for the passed parameter.
 Permanent parameters will be added to every request you make with shared settings
 It is a good place to set your auth token for example
 @param value The value, the parameter will be removed if the value passed is nil
 @param parameter The parameter of the value
 */
- (void)setPermananentParameterValue:(id)value forParameter:(NSString *)parameter;
@end
