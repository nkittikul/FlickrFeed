//
//  FFDetailViewController.m
//  FlickrFeed
//
//  Created by Narin Kittikul on 7/26/15.
//  Copyright (c) 2015 Narin Kittikul. All rights reserved.
//

#import "FFDetailViewController.h"
#import "FFDataSource.h"

@interface FFDetailViewController ()
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation FFDetailViewController

- (id)initWithImageUrl:(NSString*)urlString{
    if (self = [super init]){
        NSURL *url = [NSURL URLWithString:urlString];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        _imageView = [[UIImageView alloc] initWithImage:image];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Image";
    [self.view addSubview:self.imageView];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.imageView.frame = self.view.bounds;
}



@end
