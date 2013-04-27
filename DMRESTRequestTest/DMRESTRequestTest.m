//
//  DMRESTRequestTest.m
//  DMRESTRequestTest
//
//  Created by Thomas Ricouard on 27/04/13.
//
//

#import "DMRESTRequestTest.h"
#import "DMRESTRequest.h"

@implementation DMRESTRequestTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSettingsPrivacy
{
    STAssertEqualObjects(@"http://google.com",
                         [[[DMRESTSettings sharedSettings]baseURL]absoluteString],
                         @"FAILURE: Base URL not properly set");
    STAssertEqualObjects(@"json",
                         [[DMRESTSettings sharedSettings]fileExtension],
                         @"FAILURE: File extension not properly set");
    DMRESTSettings *privateSharedSetting = [[DMRESTSettings alloc]initForPrivateSettingsFromSharedSettings];
    STAssertEqualObjects(@"http://google.com",
                        privateSharedSetting.baseURL.absoluteString,
                         @"FAILURE: Base URL should be equal shared settings one");
    DMRESTSettings *privateprivateSettings = [[DMRESTSettings alloc]initForPrivateSettingsWithBaseURL:
                                              [NSURL URLWithString:@"http://helloworld.com"]
                                                                                        fileExtension:@"xml"];
    STAssertEqualObjects(@"http://helloworld.com",
                         privateprivateSettings.baseURL.absoluteString,
                         @"FAILURE: base URL not equal");
    STAssertEqualObjects(@"xml",
                         privateprivateSettings.fileExtension,
                         @"FAILURE: File extension not equal");
}

- (void)testSettingsPermanent
{
    [[DMRESTSettings sharedSettings]setPermanentHeaderFieldValue:@"test"
                                                  forHeaderField:@"headerTest"];
    STAssertEqualObjects(@"test", [[DMRESTSettings sharedSettings]
                                   valueForPermanentHeaderField:@"headerTest"],
                         @"FAILURE");
    [[DMRESTSettings sharedSettings]setPermanentHeaderFieldValue:nil forHeaderField:@"headerTest"];
    STAssertNil([[DMRESTSettings sharedSettings]valueForPermanentHeaderField:@"headerTest"], @"FAILURE");
    
    [[DMRESTSettings sharedSettings]setPermananentParameterValue:@"test" forParameter:@"paramTest"];
    STAssertEqualObjects(@"test", [[DMRESTSettings sharedSettings]valueForPermanentParameter:@"paramTest"], @"FAILURE");
    [[DMRESTSettings sharedSettings]setPermananentParameterValue:nil forParameter:@"paramTest"];
    STAssertNil([[DMRESTSettings sharedSettings]valueForPermanentParameter:@"paramTest"], @"FAILURE");
}

- (void)testSettingsUserAgent
{
    [[DMRESTSettings sharedSettings]setUserAgent:@"test"];
    STAssertEquals(@"test", [[DMRESTSettings sharedSettings]userAgent], @"FAILURE");
    STAssertEquals(@"test", [[DMRESTSettings sharedSettings]valueForPermanentHeaderField:@"User-Agent"], @"FAILURE");
    [[DMRESTSettings sharedSettings]setUserAgent:nil];
    STAssertNil([[DMRESTSettings sharedSettings]userAgent], @"FAILURE");
    STAssertFalse([[[DMRESTSettings sharedSettings]valueForPermanentHeaderField:@"User-Agent"]
                   isEqualToString:@"test"],
                  @"FAILURE");
}

- (void)testRequest
{
    [[DMRESTSettings sharedSettings]setBaseURL:[NSURL URLWithString:@"http://google.com"]];
    [[DMRESTSettings sharedSettings]setFileExtension:@"json"];
    
    DMRESTRequest *request = [[DMRESTRequest alloc]initWithMethod:@"GET" ressource:@"self" parameters:@{@"user": @"dimillian"}];
    [request executeBlockRequest:^(NSURLResponse *response, NSData *data, NSError *error, BOOL success) {
        if (success) {
            
        }
    }];
}

@end
