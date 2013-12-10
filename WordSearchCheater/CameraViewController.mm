//
//  CameraViewController.m
//  WordSearchCheater
//
//  Created by Nathan Swenson on 12/5/13.
//  Copyright (c) 2013 Nathan Swenson. All rights reserved.
//

#import "CameraViewController.h"
#import "CameraView.h"
#import <opencv2/highgui/cap_ios.h>
#import <TesseractOCR/TesseractOCR.h>
using namespace cv;

@interface CameraViewController () <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera *videoCamera;
@property (nonatomic, readonly) CameraView *cameraView;
@property (nonatomic, assign) NSInteger frame;

@end

@implementation CameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    self.view = [[CameraView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (CameraView*)cameraView {
    return (CameraView*)self.view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self performSelector:@selector(startCamera) withObject:nil afterDelay:1/30.0f];
}

- (void)startCamera {
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.cameraView.previewView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    self.videoCamera.delegate = self;
    [self.videoCamera start];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CvVideoCameraDelegate methods
- (void) processImage:(Mat&)image {
    Mat grayImage;
    cvtColor(image, grayImage, CV_BGRA2GRAY);
    GaussianBlur(grayImage, grayImage, cv::Size(3,3), 2);
    adaptiveThreshold(grayImage, grayImage, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 9, 15);
    int dilation_size = 1;
    Mat element = getStructuringElement(MORPH_RECT,
                                        cv::Size(2*dilation_size + 1, 2*dilation_size+1),
                                        cv::Point(dilation_size, dilation_size));
    
    // Comment out to display normal image to user
    cvtColor(grayImage, image, CV_GRAY2BGRA);
}

- (BOOL) prefersStatusBarHidden {
    return YES;
}

// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c
+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

@end
