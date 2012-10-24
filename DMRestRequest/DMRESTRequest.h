//
//  MSRESTRequest.h
//  MySeeen
//
//  Created by Thomas Ricouard on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMRESTRequestDelegate;

/**
 DMRESTRequest is here to manage REST request easily within your application
 */
@interface DMRESTRequest : NSObject <NSURLConnectionDelegate>
{

    id<DMRESTRequestDelegate>__weak delegate; 
    BOOL _shouldEscape; 
    BOOL _sendJSON; 
    NSString *_method; 
    NSString *_ressource; 
    NSDictionary *_parameters;
    NSMutableData *_responseData; 
    NSURLConnection *_connection; 
    
    
    NSString *_user; 
    NSString *_password; 
    NSString *_authEndPoint; 
    BOOL _alreadyTried; 
}
/**
 A Dictionnary you can use to totally replace defaults HTTPHeaderFields, mostly for advanced user with specific
 server configuration
 */
@property (nonatomic, strong) NSDictionary *HTTPHeaderFields; 

/**
 The timeout the request should wait before throwing an error. 
 Default value is 60 seconds (Think of Edge)
 */
@property NSTimeInterval timeout;

/**
 Define if parameters should be converted to JSON format (or not) before executing the request
 */
@property BOOL sendJSON; 

/**
 The delegate, provide various feedback when you adopt the protocol and set the delegate
 */
@property (nonatomic, weak) id<DMRESTRequestDelegate> delegate; 

/**
 Init a new standard DMRESTRequest object
 @param method The HTTP method, GET/POST/PUT/DELETE/Custom...
 @param ressource The ressource targeted for this request, as the endpoint is a constant, just provide the targeted ressource. Ie: user/new
 @param parameters A dictionnary containing the parameters to send in the request
 @param escape Define if parameters should be escaped or not
 @returns aAnew initialized object
 */
-(id)initWithMethod:(NSString *)method 
          ressource:(NSString *)ressource 
         parameters:(NSDictionary *)parameters 
shouldEscapeParameters:(BOOL)escape;


/**
 Init a new DMRESTRequest with HTTP basic auth configuration
 @param user The username for the HTTP auth credential
 @param password The password for the HTTP auth credential
 @param endPoint The full endpoint for the HTTP basic auth request 
 @return A new initialized object
 */
-(id)initForhHTTPAuthWithUser:(NSString *)user
                     password:(NSString *)password
                 authEndPoint:(NSString *)endPoint; 

/**
 Should be called when you want to execute the HTTP auth request from a properly initialized DMRESTRequest object
 Provide request feedback and status through delegate, you need to implement them for HTTP basic auth as there is no 
 block option
 */
-(void)executeHTTPAuthRequest;  

/**
 Execute standard request and provide feedback through deleate methods that you need to implement when executing the request
 with this method
 */
-(void)executeRequest;

/**
 Execute a standard request using block, provide inline response, data and error
 Please note that you may have less information and precise progress status when using block, but far more convenient 
 than implementing a bunch of delegate method
 */
-(void)executeBlockRequest:(void (^)(NSURLResponse *response, NSData *data, NSError *error, BOOL success))handler;

/**
 Cancel the current request
 */
-(void)cancelRequest; 
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

/**
 Called when the request fail because the credentials provided for the basic HTTP auth was wrong
 */
-(void)requestCredentialIncorrectForHTTPAuth; 
@end
