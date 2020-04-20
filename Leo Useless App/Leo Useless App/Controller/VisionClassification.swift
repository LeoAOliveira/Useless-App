//
//  VisionClassification.swift
//  Leo Useless App
//
//  Created by Leonardo Oliveira on 18/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import Foundation
import UIKit
import Vision

class VisionClassification {
    
    weak var viewController: ViewController?
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    // private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    private let visionQueue = DispatchQueue(label: "LeonardoAOliveira.Leo-Useless-App.serialVisionQueue")
    
    // Classification results
    var identifierString = ""
    var confidence: VNConfidence = 0.0
    
    // Vision classification request and model
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: LeoRoomObjectDetector().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
            
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func classifyCurrentImage() {
        
        let orientationRawValue: UInt32 = UInt32(UIDevice.current.orientation.rawValue)
        
        guard let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) else {
            print("Failed to get device orientation")
            return
        }
        
        guard let currentBuffer = self.currentBuffer else {
            print("Failed to get current buffer")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer, orientation: orientation)
        visionQueue.async {
            do {
                // defer releases the pixel buffer when done, allowing the next buffer to be processed.
                defer { 
                    self.currentBuffer = nil 
                }
                
                try requestHandler.perform([self.classificationRequest])
                
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Handle completion of the Vision request and choose results to display.
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        
        guard let classifications = results as? [VNRecognizedObjectObservation] else {
            return
        }
        
         print(String(describing: classifications.first?.labels.map({"\($0.identifier) confidence: \($0.confidence)"}).joined(separator: "\n")))
//        
//        print(classifications.first)
        
        if let bestResultConfidence = classifications.first?.labels.map({$0.confidence}).first, 
            let bestResultIdentifier = classifications.first?.labels.map({$0.identifier}).first {
            
            if bestResultConfidence > 0.5 {
                identifierString = String(bestResultIdentifier)
                confidence = bestResultConfidence 
                
            } else {
                print("ERROR2")
                identifierString = ""
                confidence = 0
            }
        } else {
            print("ERROR1")
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.displayClassifierResults()
        }
    }
    
    // Show the classification results in the UI.
    private func displayClassifierResults() {
        
        var title = String(format: "Procurando")
        var subtitle = String(format: "Tracking normal")
        
        if self.identifierString != "" {
            title = String(format: "\(self.identifierString)")
            subtitle = String(format: "Detectado com %.2f", self.confidence * 100) + "% de confiança"
        }
        
        guard let viewController = self.viewController else {
            return
        }
        
        viewController.titleMessage(title)
        viewController.subtitleMessage(subtitle)
    }
}
