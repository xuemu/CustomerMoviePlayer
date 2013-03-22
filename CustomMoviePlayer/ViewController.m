//
//  ViewController.m
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import "ViewController.h"
#import "PlayerControlView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    PlayerControlView *pv = [[PlayerControlView alloc]initWithFrame:CGRectMake(0, 0, 500, 500)];
    NSURL *url = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"00881.mp4"]];
    [pv setURL:url];
    [self.view addSubview:pv];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
