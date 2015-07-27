//
//  FFDataSource.m
//  FlickrFeed
//
//  Created by Narin Kittikul on 7/26/15.
//  Copyright (c) 2015 Narin Kittikul. All rights reserved.
//

#import "FFDataSource.h"
@interface FFDataSource ()
@property (nonatomic, strong) NSMutableArray *mediaFeed;
@property (nonatomic, assign) NSInteger nextPage;
@property (nonatomic, assign) BOOL loadFinished;
@property (nonatomic, strong) NSDate *lastRefreshDate;
@end

@implementation FFDataSource

- (id)init {
    if (self = [super init]){
        _lastRefreshDate = [NSDate date];
    }
    return self;
}

- (void)refresh {
    self.lastRefreshDate = [NSDate date];
    self.mediaFeed = nil;
    [self requestForPage:1];
    [self.delegate scrollToTop];
}

- (NSDictionary*)mediaInfoForRow:(NSInteger)row {
    return [self.mediaFeed objectAtIndex:row];
}

- (void)requestForPage:(NSInteger)pageNum {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://api.flickr.com/services/rest/"];
    NSURLQueryItem *method = [NSURLQueryItem queryItemWithName:@"method" value:@"flickr.photos.search"];
    NSURLQueryItem *key = [NSURLQueryItem queryItemWithName:@"api_key" value:@"b361d6266096ecd76f8ca26ab47bf703"];
    NSURLQueryItem *extras = [NSURLQueryItem queryItemWithName:@"extras" value:@"media"];
    NSURLQueryItem *tags = [NSURLQueryItem queryItemWithName:@"tags" value:@"video"];
    NSURLQueryItem *format = [NSURLQueryItem queryItemWithName:@"format" value:@"json"];
    NSURLQueryItem *perPage = [NSURLQueryItem queryItemWithName:@"per_page" value:@"20"];
    NSURLQueryItem *page = [NSURLQueryItem queryItemWithName:@"page" value:[@(pageNum) stringValue]];
    NSInteger lastRefresh = [self.lastRefreshDate timeIntervalSince1970];
    NSURLQueryItem *maxUploadDate = [NSURLQueryItem queryItemWithName:@"max_upload_date" value:[@(lastRefresh) stringValue]];
    NSURLQueryItem *noJsonCallback = [NSURLQueryItem queryItemWithName:@"nojsoncallback" value:@"1"];
    components.queryItems = @[method, key, extras, tags, format, perPage, page, maxUploadDate, noJsonCallback];
    NSURL *url = components.URL;
    [self getFeedInfoFromURL:url];
}

- (void)getFeedInfoFromURL:(NSURL*)url {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error){
            NSLog(@"Error retrieving data: %@", [error localizedDescription]);
        } else {
            [self unpackJSONData:data];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

- (void)unpackJSONData:(NSData*)data {
    NSError *error;
    NSDictionary *dict;
    dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dict){
        NSLog(@"Error converting JSON object: %@", [error localizedDescription]);
    } else {
        NSArray *mediaArray = dict[@"photos"][@"photo"];
        NSNumber *page = dict[@"photos"][@"page"];
        self.nextPage = [page integerValue] + 1;
        if (self.mediaFeed == nil && [page integerValue] == 1){
            self.mediaFeed = [[NSMutableArray alloc] initWithCapacity:[mediaArray count]];
        }
        for (NSDictionary *mediaInfo in mediaArray){
            NSString *title = mediaInfo[@"title"];
            NSString *type = mediaInfo[@"media"];
            NSString *image = [self imageURLFromInfo:mediaInfo];
            NSString *video = @"";
            if ([type isEqualToString:@"video"]){
                video = [self videoURLFromInfo:mediaInfo];
            }
            
            NSArray *objects = [NSArray arrayWithObjects:title, type, image, video, nil];
            NSArray *keys = [NSArray arrayWithObjects:@"title", @"media_type", @"image", @"video", nil];
            NSMutableDictionary *savedInfo = [NSMutableDictionary dictionaryWithObjects:objects forKeys:keys];
            if (self.mediaFeed){
                [self.mediaFeed addObject:savedInfo];
            }
        }
        self.loadFinished = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate reload];
        });
    }
}

- (NSString*)imageURLFromInfo:(NSDictionary*)info {
    NSInteger farm = [info[@"farm"] integerValue];
    NSString *photoId = info[@"id"];
    NSString *server = info[@"server"];
    NSString *secret = info[@"secret"];
    NSString *url = [NSString stringWithFormat:@"https://farm%ld.staticflickr.com/%@/%@_%@_t.jpg", (long)farm, server, photoId, secret];
    return url;
}

- (NSString*)videoURLFromInfo:(NSDictionary*)info {
    NSString *userId = info[@"owner"];
    NSString *photoId = info[@"id"];
    NSString *secret = info[@"secret"];
    NSString *url = [NSString stringWithFormat:@"http://www.flickr.com/photos/%@/%@/play/mobile/%@/", userId, photoId, secret];
    return url;

}

#pragma mark - Table View Data Source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.mediaFeed count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.row == [self.mediaFeed count]-10) && self.loadFinished){
        self.loadFinished = NO;
        [self requestForPage:self.nextPage];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"feedCell"];
    NSMutableDictionary *mediaInfo = [self.mediaFeed objectAtIndex:indexPath.row];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"feedCell"];
    }
    cell.tag = indexPath.row;
    cell.imageView.image = nil;
    
    if ([mediaInfo[@"image"] isKindOfClass:[NSString class]]){
        NSString *thumbnailUrl = mediaInfo[@"image"];
        NSURL *url = [NSURL URLWithString:thumbnailUrl];
        NSString *origImage = [thumbnailUrl stringByReplacingCharactersInRange:NSMakeRange([thumbnailUrl length]-6, 2) withString:@""];
        mediaInfo[@"original_image"] = origImage;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:data];
            if (image){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (cell.tag == indexPath.row){
                        cell.imageView.image = image;
                        [cell setNeedsLayout];
                        //cache thumbnail
                        mediaInfo[@"image"] = image;
                    }
                });
            }
        });
    } else {
        cell.imageView.image = mediaInfo[@"image"];
    }
    
    cell.textLabel.text = mediaInfo[@"title"];
    cell.detailTextLabel.text = mediaInfo[@"media_type"];
    
    return cell;
}




@end
