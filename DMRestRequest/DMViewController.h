//
//  DMViewController.h
//  DMRestRequest
//
//  Created by Thomas Ricouard on 02/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMRESTRequest.h"

@interface DMViewController : UIViewController <DMRESTRequestDelegate>
{
    DMRESTRequest *restRequest; 
}

@end
