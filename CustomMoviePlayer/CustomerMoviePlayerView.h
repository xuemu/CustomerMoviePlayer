//
//  CustomerMoviePlayerView.h
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface CustomerMoviePlayerView : UIView

@property (nonatomic, retain)AVPlayer *player;

-(void)setPlayer:(AVPlayer *)player;
-(void)setVideoFillMode:(NSString *)fillMode;
@end
