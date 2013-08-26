//
//  NSString+TotalEscaping.m
//  MySeeen
//
//  Created by Thomas Ricouard on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+TotalEscaping.h"

@implementation NSString (TotalEscaping)

-(NSString *)stringByEscapingForURLWithString:(NSString *)string
{
    NSString *espacedString = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
     NSString *totalEscapedString = [espacedString stringByReplacingOccurrencesOfString:@"'" withString:@"%27"]; 
    totalEscapedString = [totalEscapedString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]; 
    totalEscapedString = [totalEscapedString stringByReplacingOccurrencesOfString:@"&" withString:@"%26"]; 
    totalEscapedString = [totalEscapedString stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"]; 
    totalEscapedString = [totalEscapedString stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    totalEscapedString = [totalEscapedString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
   
    return totalEscapedString; 
}
@end
