//
//  FFViewController.m
//  FlickrFeed
//
//  Created by Narin Kittikul on 7/26/15.
//  Copyright (c) 2015 Narin Kittikul. All rights reserved.
//

#import "FFViewController.h"
#import "FFDetailViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface FFViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) FFDataSource *dataSource;
@property (nonatomic, strong) MPMoviePlayerViewController *playerController;

@end

@implementation FFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Recent Media";
    
    self.dataSource = [[FFDataSource alloc] init];
    [self.dataSource requestForPage:1];
    self.dataSource.delegate = self;
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self.dataSource;
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self.dataSource
                                                                             action:@selector(refresh)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.playerController = nil;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)scrollToTop {
    self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *mediaInfo = [self.dataSource mediaInfoForRow:indexPath.row];
    if ([mediaInfo[@"media_type"] isEqualToString:@"photo"]){
        FFDetailViewController *detail = [[FFDetailViewController alloc] initWithImageUrl:mediaInfo[@"original_image"]];
        [detail.view setBackgroundColor:[UIColor whiteColor]];
        [self.navigationController pushViewController:detail animated:YES];
    } else {
        NSDictionary *mediaInfo = [self.dataSource mediaInfoForRow:indexPath.row];
        NSURL *url = [NSURL URLWithString:mediaInfo[@"video"]];
        self.playerController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        [self presentMoviePlayerViewControllerAnimated:self.playerController];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableView.bounds.size.height/8;
}

#pragma mark - Data Source Delegate Methods

- (void)reload {
    [self.tableView reloadData];
}


@end
