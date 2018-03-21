//
//  ViewController.m
//  CoreMLDemo
//
//

#import "ViewController.h"

#import "Inceptionv3.h"
#import "UIImage+Utils.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession *session;
    AVCaptureDevice *device;
    AVCaptureDeviceInput *input;
    
    BOOL waitingAPI;
}
@end

@implementation ViewController

//- (NSString *)predictImageScene:(UIImage *)image {
//    GoogLeNetPlaces *model = [[GoogLeNetPlaces alloc] init];
//    NSError *error;
//    UIImage *scaledImage = [image scaleToSize:CGSizeMake(224, 224)];
//    CVPixelBufferRef buffer = [image pixelBufferFromCGImage:scaledImage];
//    GoogLeNetPlacesInput *input = [[GoogLeNetPlacesInput alloc] initWithSceneImage:buffer];
//    GoogLeNetPlacesOutput *output = [model predictionFromFeatures:input error:&error];
//    return output.sceneLabel;
//}

- (NSString *)predictImageScene:(UIImage *)image {
    Inceptionv3 *model = [[Inceptionv3 alloc] init];
    NSError *error;
    UIImage *scaledImage = [image scaleToSize:CGSizeMake(299, 299)];
    CVPixelBufferRef buffer = [image pixelBufferFromCGImage:scaledImage];
    Inceptionv3Input *input = [[Inceptionv3Input alloc] initWithImage:buffer];
    Inceptionv3Output *output = [model predictionFromFeatures:input error:&error];
    return output.classLabel;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    
    waitingAPI = NO;
    
    //Capture Session
    session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPreset352x288;
    
    //Add device
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //Input
    input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    
    [session addInput:input];
    
    //Output
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [session addOutput:videoDataOutput];
    
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)];
    
    
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    
    
    //Preview Layer
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = _cameraView.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [_cameraView.layer addSublayer:previewLayer];
    
    //Start capture session
    [session startRunning];
    
    _debugTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _debugTextView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    _debugTextView.layer.shadowOpacity = 1.0f;
    _debugTextView.layer.shadowRadius = 1.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"xx");
    if ( context == @"AVCaptureStillImageIsCapturingStillImageContext" ) {
        
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    // got an image
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    [self sendRequest:image];
    
}

- (void)sendRequest:(UIImage*)image
{
    if(!waitingAPI){
        waitingAPI = true;
        
        NSString *debug = [self predictImageScene:image];
        
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                          _debugTextView.text = debug;
                      });
        
        waitingAPI = false;
        
        
        
    }
}








// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer  {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context1 = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                  bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context1);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context1);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //I modified this line: [UIImage imageWithCGImage:quartzImage]; to the following to correct the orientation:
    UIImage *image =  [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[_cameraView.layer sublayers] firstObject].frame = _cameraView.bounds;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
