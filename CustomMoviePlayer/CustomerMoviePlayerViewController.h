//
//  CustomerMoviePlayerViewController.h
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;
@class CustomerMoviePlayerView;

@interface CustomerMoviePlayerViewController : UIViewController
{
@private
    CustomerMoviePlayerView *mPlayerView;
    
    UISlider *mScrubber;
    
}
@end
