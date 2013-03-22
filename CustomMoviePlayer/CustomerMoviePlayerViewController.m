//
//  CustomerMoviePlayerViewController.m
//  CustomMoviePlayer
//
//  Created by admin2012 on 12-11-19.
//  Copyright (c) 2012年 showone. All rights reserved.
//

#import "CustomerMoviePlayerViewController.h"

@interface CustomerMoviePlayerViewController ()

@end

@implementation CustomerMoviePlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
