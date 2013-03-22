//
//  PlayerControlView.h
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;
@class CustomerMoviePlayerView;

@interface PlayerControlView : UIView
{
@private
    CustomerMoviePlayerView *mPlaybackView;
    
    UIButton *mPlayButton;
    UIButton *mStopButton;
    
    UISlider *mScrubber;
    UIButton *mFullScreenButton;
    
    UILabel *mCurrentTimeLabel;
    UILabel *mMovieDurationLabel;
    
    float mRestoreAfterScrubbingRate;
	BOOL seekToZeroBeforePlay;
	id mTimeObserver;
    BOOL isFullSceen;
    
    NSURL* mURL;
    
	AVPlayer* mPlayer;
    AVPlayerItem * mPlayerItem;
}
@property (nonatomic, copy) NSURL* URL;
@property (readwrite, retain, setter=setPlayer:, getter=player) AVPlayer* mPlayer;
@property (retain) AVPlayerItem* mPlayerItem;
@property (nonatomic, retain) CustomerMoviePlayerView *mPlaybackView;
@property (nonatomic,assign)CGRect oriFrame;
@property (nonatomic, retain) UIButton *mPlayButton;
@property (nonatomic, retain) UIButton *mStopButton;
@property (nonatomic, retain) UISlider *mScrubber;
@property (nonatomic, retain) UIButton *mFullScreenButton;
@property (nonatomic, retain) UILabel *mCurrentTimeLabel;
@property (nonatomic, retain) UILabel *mMovieDurationLabel;


@end
