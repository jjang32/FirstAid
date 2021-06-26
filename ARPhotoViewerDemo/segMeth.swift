//
//  segMeth.swift
//  ARPhotoViewerDemo
//
//  Created by Benjamin Crespo on 6/26/21.
//  Copyright © 2021 DAYE JACK. All rights reserved.
//

import Foundation
import UIKit
import Vision

/*class segMeth{
    var segmentedImage: UIImage?
    var maskImage: UIImage?
   static func predict(customRequest: VNCoreMLRequest?, customImage: UIImage?) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let request = customRequest else { fatalError() }
            let handler = VNImageRequestHandler(cgImage: (customImage?.cgImage)!, options: [:])
            do {
                print("Request Made")
                try handler.perform([request])
            }catch {
                print(error)
            }
        }
    }
    
func visionRequestDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            
            /*
             Checks if the output is of type PixelBuffer or MultiArray:
                - U2-Net return CVPixelBuffer
                - Deep-Lab returns MLMultiArray
            */
            var top = Int.max, left = Int.max, right = Int.min, bottom = Int.min
            if let observations = request.results as? [VNPixelBufferObservation],
               let segmentationmap = observations.first?.pixelBuffer {
                self.maskImage = segmentationmap.createImage()
            }else if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                     let segmentationmap = observations.first?.featureValue.multiArrayValue {
                if let (b, w, h) = segmentationmap.toRawBytes(min: 0, max: 255){
                    for i in 0...h - 1{
                        for j in 0...w - 1{
                            if(b[i * w  + j] == 255) {
                                top = min(top, i)
                                bottom = max(bottom, i)
                                left = min(left, j)
                                right = max(right, j)
                            }
                        }
                    }
    
                }
            }
        }
    }
    
    
}*/
        
