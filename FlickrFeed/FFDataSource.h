//
//  FFDataSource.h
//  FlickrFeed
//
//  Created by Narin Kittikul on 7/26/15.
//  Copyright (c) 2015 Narin Kittikul. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DataSourceDelegate <NSObject>
@required
- (void)reload;
- (void)scrollToTop;
@end

@interface FFDataSource : NSObject <UITableViewDataSource>
@property (nonatomic, weak) id<DataSourceDelegate> delegate;

- (void)requestForPage:(NSInteger)page;
- (NSDictionary*)mediaInfoForRow:(NSInteger)row;
- (void)refresh;

@end
