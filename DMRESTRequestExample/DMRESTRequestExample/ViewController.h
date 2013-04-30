//
//  ViewController.h
//  DMRESTRequestExample
//
//  Created by Thomas Ricouard on 4/30/13.
//  Copyright (c) 2013 Thomas Ricouard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DMRESTRequest/DMRESTRequest.h>

@interface ViewController : UIViewController <DMRESTRequestDelegate>
{
    DMRESTRequest *_restRequest;
}
@end
