//
//  ViewController.swift
//  ios-camera-video-preview-uiimage
//
//  Created by Zhaonan Li on 8/5/16.
//  Copyright © 2016 Zhaonan Li. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraImageView: UIImageView!

    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetPhoto
        //s.sessionPreset = AVCaptureSessionPresetHigh
        return s
    }()
    
    lazy var ciContext: CIContext = {
        let ciContext = CIContext(options: nil)
        return ciContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupCameraSession()
    }
    
    override func viewDidAppear(animated: Bool) {
        cameraSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupCameraSession() {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as AVCaptureDevice
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = dispatch_queue_create("com.invasivecode.videoQueue", DISPATCH_QUEUE_SERIAL)
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // Here you collect each frame and process it
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(CVPixelBuffer: pixelBuffer!)
        
        // Rotate image 90 degree to right.
        var tx = CGAffineTransformMakeTranslation(
            image.extent.width / 2,
            image.extent.height / 2)
        
        tx = CGAffineTransformRotate(
            tx,
            CGFloat(-1 * M_PI_2))
        
        tx = CGAffineTransformTranslate(
            tx,
            -image.extent.width / 2,
            -image.extent.height / 2)
        
        var transformImage = CIFilter(
            name: "CIAffineTransform",
            withInputParameters: [
                kCIInputImageKey: image,
                kCIInputTransformKey: NSValue(CGAffineTransform: tx)])!.outputImage!
        
        // Apply the filter on the image.
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setDefaults()
        filter?.setValue(transformImage, forKey: kCIInputImageKey)
        transformImage = (filter?.outputImage)!
        
        dispatch_async(dispatch_get_main_queue()) {
            // When call UIImage(CIImage: ciImage), a new CIContext will be created, 
            // which is not very effecient.
            // Here reuse the CIContext, and convert the CIImage into CGImage,
            // then convert CGImage into UIImage, which is more effecient.
            let cgImage = self.ciContext.createCGImage(transformImage, fromRect: transformImage.extent)
            self.cameraImageView.image = UIImage(CGImage: cgImage)
        }
    }
}
