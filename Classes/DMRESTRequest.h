//
//  DMRESTRequest.h
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMRESTSettings.h"
@class DMRESTHTTPAuthCredential;
@protocol DMRESTRequestDelegate;
/**
 DMRESTRequest is here to manage REST request easily within your application
 */
@interface DMRESTRequest : NSObject <NSURLConnectionDelegate>

/**
 The delegate, provide various feedback when you adopt the protocol and set the delegate
 You don't need it if you only use block methods
 */
@property (nonatomic, weak) id<DMRESTRequestDelegate> delegate;


/**
 Set this property to use the passed settings instead of the shared settings
 If not set it will use the DMRESTSettings sharedSettings settings you've set.
 */
@property (nonatomic, strong) DMRESTSettings *privateCustomSettings;

/**
 Designated initializer, init a new standard DMRESTRequest object
 @param method The HTTP method, GET/POST/PUT/DELETE/Custom...
 @param ressource The ressource targeted for this request, as the endpoint is a constant, just provide the targeted ressource. Ie: user/new
 @param parameters A dictionnary containing the parameters to send in the request
 @returns aAnew initialized object
 */
-(id)initWithMethod:(NSString *)method 
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters;

/**
 Execute a standard request using block, provide inline response, data and error
 */
-(void)executeBlockRequest:(void (^)(NSURLResponse *response, NSData *data, NSError *error, BOOL success))handler;

/**
 Execute a standard request using block, provide inline response, data and error
 Also provide a block that let you a chance to provide you own HTTPAUth Credential
 */
-(void)executeBlockRequest:(void (^)(NSURLResponse *response, NSData *data, NSError *error, BOOL success))handler
                                    requestAskforHTTPAuth:(DMRESTHTTPAuthCredential *(^)(void))httpAuthBlock;

/**
 Execute a standard request using block, provide different callback as block, it emulate delegate but with block
 responseBlock: Called first, contain the response, http status code and exepted content size
 httpAuthBlock: Called when the request need credential for HTTP auth, you can return nil
 progressBlock: Called multiple time during the request, provide the data downloaded so far and the % of progression
 errorBlock: Called when the request fail with an error
 completionBlock: Called once the request is done, provide complete data
 */
-(void)executeDetailedBlockRequestReceivedResponse:(void (^)(NSURLResponse *response,
                                                             NSInteger httpStatusCode,
                                                             long long exeptedContentSize))responseBlock
                             requestAskforHTTPAuth:(DMRESTHTTPAuthCredential *(^)(void))httpAuthBlock
                          progressWithReceivedData:(void (^)(NSData *currentData, NSData *newData, NSUInteger currentLength))progressBlock
                                   failedWithError:(void(^)(NSError *error))errorBlock
                                   finishedRequest:(void(^)(NSData *completeData))completionBlock;

/**
 Execute the request using delegate, you must set the delegate before calling this method
 */
-(void)executeRequestWithDelegate;

/**
 Cancel the current request
 */
-(void)cancelRequest; 
@end

/**
 DMRESTHTTPAuthLogin is a simple object providing an interface to forward credential when DMRESTRequest 
 ask for them
 */
@interface DMRESTHTTPAuthCredential : NSObject

@property (nonatomic, copy, readonly) NSString *login;
@property (nonatomic, copy, readonly) NSString *password;
@property (nonatomic, readonly) BOOL continueLogin;

/**
 Init a new DMRESTHTTPAuthLogin
 @param user The username for the HTTP auth credential
 @param password The password for the HTTP auth credential
 @param login should login or not, set YES if you want to relaunch the DMRESTRequest and login with pssed
 credential
 @return A new initialized object
 */
- (id)initWithLogin:(NSString *)login
           password:(NSString *)password
      continueLogin:(BOOL)continueLogin;
@end


/**
 The protocol you should conform and implement if you want to use the delegate feedback of DMRESTRequest
 */
@protocol DMRESTRequestDelegate <NSObject>
@required
/**
 Called as soon as the request start, usefull to display a loading screen or something
 */
-(void)requestDidStart;

/**
 Called as soon as the request finished loading with a JSON response
 @param json A NSJSONSerialization initialized object containing the request response
 */
-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json;

/**
 Called when the request fail with en error
 @param error The error contaning the code and description
 */
-(void)requestDidFailWithError:(NSError *)error;
@optional
/**
 Called when the request have the HTTP status code
 @param status The HTTP status code returned by the server
 */
-(void)requestDidRespondWithHTTPStatus:(NSInteger)status;

/**
 Called when the request finish loading with data, use this when you don't want JSON but the actual non formatted data
 returned by the server
 @param data The data returned by the server.
 */
-(void)requestDidFinishWithData:(NSMutableData *)data;

/**
 Called when the request fail because no active internet connection is present on the device
 */
-(void)requestDidFailBecauseNoActiveConnection;

@end
