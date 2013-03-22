//
//  PlayerControlView.m
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import "PlayerControlView.h"
#import "CustomerMoviePlayerView.h"


/* Asset keys */
NSString * const kTracksKey         = @"tracks";
NSString * const kPlayableKey		= @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

@interface PlayerControlView()
- (void)setFullScreen:(id)sender;
- (void)play:(id)sender;
- (void)pause:(id)sender;
- (void)showMetadata:(id)sender;
- (void)initScrubberTimer;
- (void)showPlayButton;
- (void)showStopButton;
- (void)syncScrubber;
- (void)beginScrubbing:(id)sender;
- (void)scrub:(id)sender;
- (void)endScrubbing:(id)sender;
- (BOOL)isScrubbing;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (id)init;
- (void)dealloc;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)viewDidLoad;
- (void)viewWillDisappear:(BOOL)animated;
- (void)handleSwipe:(UISwipeGestureRecognizer*)gestureRecognizer;
- (void)syncPlayPauseButtons;
- (void)setURL:(NSURL*)URL;
- (NSURL*)URL;

@end

@interface PlayerControlView(Player)
- (void)removePlayerTimeObserver;
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)playerItemDidReachEnd:(NSNotification *)notification ;
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;

@implementation PlayerControlView
@synthesize mCurrentTimeLabel,mFullScreenButton,mMovieDurationLabel,mPlayButton,mScrubber,mStopButton;
@synthesize mPlayer,mPlaybackView,mPlayerItem,oriFrame;

-(void)dealloc
{
    [self removePlayerTimeObserver];
	
	[mPlayer removeObserver:self forKeyPath:@"rate"];
	[mPlayer.currentItem removeObserver:self forKeyPath:@"status"];
	
	[mPlayer pause];
	[mPlayer release];
	
	[mURL release];
    
    self.mPlaybackView = nil;

    self.mPlayButton = nil;
    self.mStopButton = nil;
    self.mScrubber = nil;
    
    [mTimeObserver release];
    
    [mURL release];
    [mCurrentTimeLabel release];
    [mFullScreenButton release];
    [mMovieDurationLabel release];
    [mPlayButton release];
    [mScrubber release];
    [mStopButton release];
    
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.oriFrame = frame;
        isFullSceen = NO;
        mPlayer = nil;
        
        mPlaybackView = [[CustomerMoviePlayerView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - 50)];
        [self addSubview:mPlaybackView];
        
        UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        playBtn.frame = CGRectMake(1, frame.size.height - 49, 48, 48);
        [playBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
        [playBtn setTitle:@"Play" forState:UIControlStateNormal];
        
        [self addSubview:playBtn];
        self.mPlayButton = playBtn;
        
        UIButton *pauseBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        pauseBtn.frame = CGRectMake(1, frame.size.height - 49, 48, 48);
        [pauseBtn addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
        [pauseBtn setTitle:@"Pause" forState:UIControlStateNormal];
        
        pauseBtn.titleLabel.text = @"Pause";
        self.mStopButton = pauseBtn;
        [self addSubview:pauseBtn];
        
        mCurrentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(51, frame.size.height-50, 60, 20)];
        mCurrentTimeLabel.backgroundColor = [UIColor clearColor];
        mCurrentTimeLabel.textAlignment = UITextAlignmentLeft;
        mCurrentTimeLabel.font = [UIFont systemFontOfSize:17.f];
        [self addSubview:mCurrentTimeLabel];
       
        mScrubber = [[UISlider alloc]initWithFrame:CGRectMake(51, frame.size.height-40, frame.size.width-101, 48)];
        [self addSubview:mScrubber];
        [mScrubber addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [mScrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [mScrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        [mScrubber addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
        
        mMovieDurationLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width - 50 - 60, frame.size.height-50, 60, 20)];
        mMovieDurationLabel.backgroundColor = [UIColor clearColor];
        mMovieDurationLabel.textAlignment = UITextAlignmentRight;
        mMovieDurationLabel.font = [UIFont systemFontOfSize:16.f];
        [self addSubview:mMovieDurationLabel];
        
        
        UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [fullScreenBtn addTarget:self action:@selector(setFullScreen:) forControlEvents:UIControlEventTouchUpInside];
        fullScreenBtn.frame = CGRectMake(frame.size.width-49, frame.size.height-49, 48, 48);
        [self addSubview:fullScreenBtn];
        self.mFullScreenButton = fullScreenBtn;
        
        [self showPlayButton];
        
        [self initScrubberTimer];
        
        [self syncPlayPauseButtons];
        [self syncScrubber];
    }
    return self;
}

#pragma mark Asset URL

- (void)setURL:(NSURL*)URL
{
	if (mURL != URL)
	{
		[mURL release];
		mURL = [URL copy];
		mURL = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"00881.mp4"]];
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys "tracks", "playable".
         */
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:mURL options:nil];
        
        NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{
             dispatch_async( dispatch_get_main_queue(),
                            ^{
                                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
	}
}

- (NSURL*)URL
{
	return mURL;
}

#pragma mark -
#pragma mark Movie controller methods

#pragma mark
#pragma mark Button Action Methods

- (void)setFullScreen:(id)sender
{
    [UIView animateWithDuration:.8 animations:^{
        if (!isFullSceen) {
            
            [self setFrame:CGRectMake(0, 0, 768, 1004)];
            self.backgroundColor = [UIColor darkGrayColor];
        }else{
            [self setFrame:self.oriFrame];
            self.backgroundColor = [UIColor clearColor];
        }
        
        mCurrentTimeLabel.frame = CGRectMake(51, self.frame.size.height-50, 60, 20);
        mMovieDurationLabel.frame = CGRectMake(self.frame.size.width - 50 - 60, self.frame.size.height-50, 60, 20);
        mPlaybackView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 55);
        mScrubber.frame = CGRectMake(51, self.frame.size.height-40, self.frame.size.width-101, 48);
        mStopButton.frame = CGRectMake(1, self.frame.size.height - 49, 48, 48);
        mPlayButton.frame = CGRectMake(1, self.frame.size.height - 49, 48, 48);
        mFullScreenButton.frame = CGRectMake(self.frame.size.width-49, self.frame.size.height - 49, 48, 48);
        
    }];
    
    isFullSceen = !isFullSceen;
}

- (void)play:(id)sender
{
	/* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
	if (YES == seekToZeroBeforePlay)
	{
		seekToZeroBeforePlay = NO;
		[mPlayer seekToTime:kCMTimeZero];
	}
    
	[mPlayer play];
	
    [self showStopButton];
}


- (void)pause:(id)sender
{
	[mPlayer pause];


    [self showPlayButton];
}

#pragma mark -
#pragma mark Play, Stop buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
//    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[mToolbar items]];
//    [toolbarItems replaceObjectAtIndex:0 withObject:mStopButton];
//    mToolbar.items = toolbarItems;
    self.mStopButton.enabled = YES;
    self.mStopButton.hidden = NO;
    self.mPlayButton.enabled = NO;
    self.mPlayButton.hidden = YES;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
//    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[mToolbar items]];
//    [toolbarItems replaceObjectAtIndex:0 withObject:mPlayButton];
//    mToolbar.items = toolbarItems;
    
    self.mStopButton.enabled = NO;
    self.mStopButton.hidden = YES;
    self.mPlayButton.enabled = YES;
    self.mPlayButton.hidden = NO;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];
	}
}

-(void)enablePlayerButtons
{
    self.mPlayButton.enabled = YES;
    self.mStopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.mPlayButton.enabled = NO;
    self.mStopButton.enabled = NO;
}

#pragma mark -
#pragma mark Movie scrubber control

-(void)updateCurrentTimeLabel:(double)time
{
    self.mCurrentTimeLabel.text = [self getTimeStringWithTime:time];
}

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = .1f;
	
	CMTime playerDuration = [self playerItemDuration];
    
	if (CMTIME_IS_INVALID(playerDuration))
	{
		return;
	}
	double duration = CMTimeGetSeconds(playerDuration);
    NSLog(@"=========duration = %f",duration);
    self.mMovieDurationLabel.text = [self getTimeStringWithTime:duration];
    if (duration < 60*60) {
        self.mCurrentTimeLabel.text = @"00:00";
    }else{
        self.mCurrentTimeLabel.text = @"00:00:00";
    }
    
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([mScrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
	/* Update the scrubber during normal playback. */
	mTimeObserver = [[mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                           queue:NULL /* If you pass NULL, the main queue is used. */
                                                      usingBlock:^(CMTime time)
                      {
                          [self syncScrubber];
                      }] retain];
    
}

- (NSString *)getTimeStringWithTime:(double)time {
    int seconds = (int)time % 60;
    int minutes = ((int)time - seconds) % (60 * 60);
    int hours = (time - minutes - seconds);
    
    if (hours > 0)

        return [NSString stringWithFormat:@"%@:%@:%@",[self isAddZero:hours / 60 / 60], [self isAddZero:minutes / 60], [self isAddZero:seconds]];
    else
        return [NSString stringWithFormat:@"%@:%@", [self isAddZero:(minutes / 60)], [self isAddZero:seconds]];
}

- (NSString *)isAddZero:(int)number
{
    if (number < 10) {
        return [NSString stringWithFormat:@"0%d",number];
    }else{
        return [NSString stringWithFormat:@"%d",number];
    }
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		mScrubber.minimumValue = 0.0;
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
    
	if (isfinite(duration))
	{
		float minValue = [mScrubber minimumValue];
		float maxValue = [mScrubber maximumValue];
		double time = CMTimeGetSeconds([mPlayer currentTime]);

        [self updateCurrentTimeLabel:time];
		[mScrubber setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing:(id)sender
{
	mRestoreAfterScrubbingRate = [mPlayer rate];
	[mPlayer setRate:0.f];
	
	/* Remove previous timer. */
	[self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (void)scrub:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
            [self updateCurrentTimeLabel:time];
            seekToZeroBeforePlay = NO;
			[mPlayer seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing:(id)sender
{
	if (!mTimeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration))
		{
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([mScrubber bounds]);
			double tolerance = 0.5f * duration / width;
            
			mTimeObserver = [[mPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:NULL usingBlock:
                              ^(CMTime time)
                              {
                                  [self syncScrubber];
                              }] retain];
		}
	}
    
	if (mRestoreAfterScrubbingRate)
	{
		[mPlayer setRate:mRestoreAfterScrubbingRate];
		mRestoreAfterScrubbingRate = 0.f;
	}
}

- (BOOL)isScrubbing
{
	return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.mScrubber.enabled = YES;
}

-(void)disableScrubber
{
    self.mScrubber.enabled = NO;
}

@end

@implementation PlayerControlView(Player)

#pragma mark Player Item

- (BOOL)isPlaying
{
	return mRestoreAfterScrubbingRate != 0.f || [mPlayer rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	/* After the movie has played to its end time, seek back to time zero
     to play it again. */
	seekToZeroBeforePlay = YES;
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
	AVPlayerItem *playerItem = [mPlayer currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay)
	{
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (mTimeObserver)
	{
		[mPlayer removeTimeObserver:mTimeObserver];
		[mTimeObserver release];
		mTimeObserver = nil;
	}
}

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


#pragma mark Prepare to play asset, URL

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey,
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.mPlayerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.mPlayerItem removeObserver:self forKeyPath:kStatusKey];
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.mPlayerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.mPlayerItem addObserver:self
                       forKeyPath:kStatusKey
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.mPlayerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.mPlayerItem]];
		
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.mPlayerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.mPlayerItem];
        
        [self syncPlayPauseButtons];
    }
	
    [mScrubber setValue:0.0];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if (context == AVPlayerDemoPlaybackViewControllerStatusObservationContext)
	{
		[self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self initScrubberTimer];
                
                [self enableScrubber];
                [self enablePlayerButtons];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == AVPlayerDemoPlaybackViewControllerRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
	else if (context == AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [mPlaybackView setPlayer:mPlayer];
            
//            [self setViewDisplayName];
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            [mPlaybackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}

@end
