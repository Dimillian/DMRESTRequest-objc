//
//  ViewController.m
//  DMRESTRequestExample
//
//  Created by Thomas Ricouard on 4/30/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

#import "ViewController.h"
#import <DMRESTRequest/DMJSONCache.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[DMRESTSettings sharedSettings]setBaseURL:[NSURL URLWithString:@"https://api.virtual-info.info"]];
    [[DMRESTSettings sharedSettings]setFileExtension:@"json"];
    //Adding some permanent parameter like a AuthToken
    [[DMRESTSettings sharedSettings]setPermananentParameterValue:@"1234" forParameter:@"AuthToken"];
    NSLog(@"%@", [[DMRESTSettings sharedSettings]valueForPermanentParameter:@"AuthToken"]);
    
    [self simpleCachedJSONBlockRequest];
    [self simpleBlockRequest];
    [self complexeBlockRequest];
    [self privateSettingsBlockRequest];
    [self httpAuthBlockRequest];
    [self delegateRequest];

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)simpleBlockRequest
{
    
    //Block method, short method without using the delegate.
    //This is the preferred way
    DMRESTRequest *blockrestRequest = [[DMRESTRequest alloc]initWithMethod:@"GET"
                                                                 ressource:@"self"
                                                                parameters:@{@"user": @"Dimillian"}];
    [blockrestRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success){
        if (error || !success) {
            //TODO show error message
        }
        else{
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
            NSLog(@"%@", json);
            //TODO do something with response
        }
    }];
}

- (void)simpleCachedJSONBlockRequest
{
    //Simple block JSON request when you are sure that your API return JSON, DMRESTRequest take care of returnin a JSONObject which can be a
    //NSDictionnary or a NSArray
    DMRESTRequest *request = [[DMRESTRequest alloc]initWithMethod:@"GET"
                                                        ressource:@"self"
                                                       parameters:@{@"user": @"dimillian"}];
    [request executeJSONBlockRequestWithCache:YES
                            JSONReadingOption:NSJSONReadingAllowFragments
                                   completion:^(NSURLResponse *response, id JSONObject, NSError *error, BOOL success, BOOL fromCache) {
                                       NSDictionary *jsonDic = (NSDictionary *)JSONObject;
                                       if (fromCache) {
                                           NSLog(@"CACHED JSON: %@", jsonDic);
                                       }
                                       else{
                                           NSLog(@"SERVER JSON: %@", jsonDic);
                                           
                                       }
        
    }];
}

- (void)complexeBlockRequest
{
    //Complexe block usage
    //Provide more feedback with more detail
    DMRESTRequest *complexeBlockRequest = [[DMRESTRequest alloc]initWithMethod:@"POST"
                                                                     ressource:@"self"
                                                                    parameters:@{@"user": @"Dimillian", @"query": @"full"}];
    
    [complexeBlockRequest executeDetailedBlockRequestReceivedResponse:^(NSURLResponse *response, NSInteger httpStatusCode, long long exeptedContentSize) {
        
    } requestAskforHTTPAuth:^DMRESTHTTPAuthCredential *{
        return nil;
    } progressWithReceivedData:^(NSMutableData *currentData, NSData *newData, NSUInteger currentSize) {
        NSLog(@"%lu", (unsigned long)currentSize);
    } failedWithError:^(NSError *error) {
        NSLog(@"%@", error);
    } finishedRequest:^(NSData *completeData) {
        NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:completeData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:nil];
        NSLog(@"%@", json);
    }];
    
}


- (void)privateSettingsBlockRequest
{
    //Example with custom setting for this request, send HTTPBody as JSON
    DMRESTSettings *settings = [[DMRESTSettings alloc]initForPrivateSettingsFromSharedSettings];
    [settings setSendJSON:YES];
    [settings setUserAgent:@"DMRESTRequest/version type/JSON"];
    DMRESTRequest *postRequest = [[DMRESTRequest alloc]initWithMethod:@"POST"
                                                            ressource:@"self"
                                                           parameters:@{@"user": @"dimillian",
                                  @"movies": [NSNumber numberWithInt:1]}];
    [postRequest setPrivateCustomSettings:settings];
    [postRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success) {
        if (success) {
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
            NSLog(@"%@", json);
        }
    }];
}

- (void)httpAuthBlockRequest
{
    //Other example using simple block method with HTTP auth
    DMRESTSettings *authSettings = [[DMRESTSettings alloc]initForPrivateSettingsWithBaseURL:
                                    [NSURL URLWithString:@"http://auth.api.virtual-info.info/"]];
    DMRESTRequest *authRequest = [[DMRESTRequest alloc]initWithMethod:@"GET" ressource:@"" parameters:nil];
    [authRequest setPrivateCustomSettings:authSettings];
    [authRequest executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success) {
        NSLog(@"%@", response);
        NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", string);
    } requestAskforHTTPAuth:^DMRESTHTTPAuthCredential *{
        NSLog(@"ASK LOGIn");
        DMRESTHTTPAuthCredential *login = [[DMRESTHTTPAuthCredential alloc]initWithLogin:@"azerty" password:@"azerty" continueLogin:YES];
        return login;
    }];
}

- (void)delegateRequest
{
    
    
    //Other example with multiple parameters and other properties and using delegate
    _restRequest = [[DMRESTRequest alloc]initWithMethod:@"POST"
                                                           ressource:@"users"
                                                          parameters:
                                 [NSDictionary dictionaryWithObjectsAndKeys:@"13", @"userId", @"Dimillian", @"username", nil]];
    DMRESTSettings *privateSettings = [[DMRESTSettings alloc]initForPrivateSettingsWithBaseURL:
                                       [NSURL URLWithString:@"http://google.com"]];
    [privateSettings setFileExtension:@"json"];
    privateSettings.customTimemout = 40;
    privateSettings.sendJSON = YES;
    [_restRequest setDelegate:self];
    [_restRequest executeRequestWithDelegate];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - DMRestRequest delegate

-(void)requestDidStart
{
    NSLog(@"START");
    //The request just started, you should start your loading screen or something
}

-(void)requestDidRespondWithHTTPStatus:(NSInteger)status
{
    NSLog(@"STATUS %d", status);
    //Useful if you rely on HTTP status code on your client to do some opérations.
    //This delegate will be called first after requestDidStart.
    
    //ie if(status==200) OK
}

-(void)requestDidFinishWithJSON:(NSJSONSerialization *)json
{
    
    NSLog(@"JSON %@", json);
    //Request is finished with success and you have the full JSON response from your server.
    //The response can be an NSDictionnary or an NSArray (mutable).
    
    //ie: NSDictionary *jsonDic = (NSDictionary*)json;
    
    //This is where you can parse it into your model object and start doing some crazy shit
}

-(void)requestDidFailWithError:(NSError *)error
{
    //Request did fail with an error, check the error to know why and refresh your UI.
}

-(void)requestDidFailBecauseNoActiveConnection
{
    //No active connection detected
    //you should display en error message
}

-(void)requestCredentialIncorrectForHTTPAuth
{
    //Crendential provided incorect
}


@end
