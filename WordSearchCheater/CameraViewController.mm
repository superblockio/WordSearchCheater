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
    // Initial cleanup of image
    Mat grayImage;
    cvtColor(image, grayImage, CV_BGRA2GRAY);
    GaussianBlur(grayImage, grayImage, cv::Size(3,3), 2);
    adaptiveThreshold(grayImage, grayImage, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 9, 15);
    
    // Find a set of points representing possible letters
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(grayImage, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    vector<vector<cv::Point>> contours_poly( contours.size() );
    vector<cv::Rect> boundRect( contours.size() );
    for (int i = 0; i < contours.size(); i++) {
        approxPolyDP(Mat(contours[i]), contours_poly[i], 15, true);
        boundRect[i] = boundingRect(Mat(contours_poly[i]));
        //rectangle(image, boundRect[i].tl(), boundRect[i].br(), Scalar(0, 255, 0));
    }
    
    Mat features(boundRect.size(), 2, CV_32F);
    features = -100000;
    for (int i = 0; i < boundRect.size(); i++) {
        // Only count points that are within a certain size range
        if (boundRect[i].area() < 10000.0f && boundRect[i].area() > 50.0f) {
            features.at<float>(i, 0) = boundRect[i].tl().x;
            features.at<float>(i, 0) = boundRect[i].tl().y;
            // draw rectangles
            //rectangle(image, boundRect[i].tl(), boundRect[i].br(), Scalar(0, 255, 0));
        }
    }
    
    // Using a graph representation, add an edge between all points that are within a certain radius
    // of each other, from the center of the image out, to find all points in the "connected" region
    // that we believe compose the wordsearch grid.
    if (features.size[0] > 0) {
        flann::Index index = flann::Index(features, flann::KDTreeIndexParams());
        vector<int> neighbors(4);
        vector<float> dists(4);
        index.radiusSearch(vector<float>(720/2, 1280/2), neighbors, dists, 100.0f, 4);
        for (int i =0; i < boundRect.size(); i++) {

        }
    }
    
    
    // Comment out to display normal image to user
    //cvtColor(grayImage, image, CV_GRAY2BGRA);
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
