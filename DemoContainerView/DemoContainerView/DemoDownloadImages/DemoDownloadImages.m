
//  Created by Rustam Motygullin on 09.08.2018.
//  Copyright © 2018 mrusta. All rights reserved.

#import "DemoDownloadImages.h"
#import "ContainerMacros.h"

NSString *const kSaveImagesDocuments = @"saveImagesDocuments";

typedef NS_ENUM(NSUInteger, ImageType) {
    ImageTypeBig = 0,
    ImageTypeSmall,
};

@interface DemoDownloadImages () {
    NSMutableDictionary <NSString *,NSNumber *> *saveLocalImageURLs;
    NSArray <NSString *> *imageURLs;
}

@end

@implementation DemoDownloadImages


- (void)startLoadImages {
    
    if(!imageURLs) {
        imageURLs = [self loadLocalJSONimageURLs];
    }
    
    NSArray *saveDocumentsImageURLs = [[NSUserDefaults standardUserDefaults] valueForKey:kSaveImagesDocuments];
    if(saveDocumentsImageURLs == nil) {
        saveLocalImageURLs = [NSMutableDictionary new];
    } else {
        saveLocalImageURLs = [saveDocumentsImageURLs mutableCopy];
        
        NSInteger i =0;
        while(i < saveLocalImageURLs.count)
        {
            UIImage *img      = [self loadLocalImageType:ImageTypeBig   index:i];
            UIImage *imgSmall = [self loadLocalImageType:ImageTypeSmall index:i];
            
            if(self.blockAddImage && img && imgSmall) self.blockAddImage(img, imgSmall, NO);
            
            i++;
        }
        
    }
    
    [self loadImagesOtherQueue];
    
}


- (void)loadImagesOtherQueue {
    
    networkIndicatorOn(YES);
    
    __weak NSArray *weakImageURLs = imageURLs;
    __weak NSMutableDictionary *weakSaveLocalImageURLs = saveLocalImageURLs;
    
    
    dispatch_async(dispatch_queue_create("downloadImagesOtherQueue", NULL), ^{
        
        NSInteger i =0;
        
        while(i < weakImageURLs.count)
        {
            NSString *strImageURL = weakImageURLs[i];
            
            NSNumber *findIndex = weakSaveLocalImageURLs[strImageURL];
            if(!findIndex) {
                
                NSData *imgData = [self donwloadURL:strImageURL];
                
                UIImage *img = [UIImage imageWithData:imgData];
                UIImage *imgSmall = [self imageWithImage:img size:200];
                NSData *imgDataSmall = UIImageJPEGRepresentation(imgSmall, 1);
                
                if(img && imgSmall) {
                    
                    [self saveLocalImageType:ImageTypeBig   imgData:imgData      index: weakSaveLocalImageURLs.count];
                    [self saveLocalImageType:ImageTypeSmall imgData:imgDataSmall index: weakSaveLocalImageURLs.count];
                    
                    [weakSaveLocalImageURLs setObject:@(weakSaveLocalImageURLs.count) forKey:strImageURL];
                    [[NSUserDefaults standardUserDefaults] setObject:weakSaveLocalImageURLs forKey:kSaveImagesDocuments];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(self.blockAddImage) self.blockAddImage(img, imgSmall, YES);
                    });
                }
            }
            
            i++;
            
            if(i >= weakImageURLs.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    networkIndicatorOn(NO);
                });
            }
            
        }
    });
}

- (NSData *)donwloadURL:(NSString *)strURL {
    return [NSData dataWithContentsOfURL:[NSURL URLWithString:strURL]];
}


- (UIImage *)loadLocalImageType:(ImageType)imageType index:(NSInteger)index {
    
    NSString *imagePath;
    switch (imageType) {
        case ImageTypeBig:   imagePath = [self documentsPathFileName:SFMT(@"IMG_%d@3x.jpg",    (int)index)]; break;
        case ImageTypeSmall: imagePath = [self documentsPathFileName:SFMT(@"IMG_%d.jpg", (int)index)]; break;
        default: break;
    }
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
}


- (void)saveLocalImageType:(ImageType)imageType imgData:(NSData *)imgData index:(NSInteger)index {
    
    switch (imageType) {
        case ImageTypeSmall: [imgData writeToFile:[self documentsPathFileName:SFMT(@"IMG_%d.jpg",    (int)index)] atomically:YES]; break;
        case ImageTypeBig:   [imgData writeToFile:[self documentsPathFileName:SFMT(@"IMG_%d@3x.jpg", (int)index)] atomically:YES]; break;
        default: break;
    }
}


- (NSArray *)loadLocalJSONimageURLs
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"imageURLs" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    return result;
}

- (NSString *)documentsPathFileName:(NSString *)name {
    return [documentsPath stringByAppendingPathComponent:name];
}

- (UIImage *)imageWithImage:(UIImage *)image size:(NSInteger)size {
    
    CGSize cgSize = (CGSize) {         size, (image.size.height / (image.size.width / size) )};
    CGRect cgRect = (CGRect) {{0, 0}, {size, (image.size.height / (image.size.width / size) )}};
    UIGraphicsBeginImageContextWithOptions( cgSize, NO, 0.0);
    [image drawInRect: cgRect ];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
