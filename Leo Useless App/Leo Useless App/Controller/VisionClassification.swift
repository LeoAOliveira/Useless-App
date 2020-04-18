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
    public var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    // private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    private let visionQueue = DispatchQueue(label: "LeonardoAOliveira.Leo-Useless-App.serialVisionQueue")
    
    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    
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
    
    private func classifyCurrentImage() {
        
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
        // The results will always be VNRecognizedObjectObservation
        
        print(request)
        
        guard let classifications = results as? [VNRecognizedObjectObservation] else {
            return
        }
        
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            let label = bestResult.labels.map({$0.identifier}).first {
            identifierString = String(label)
            confidence = bestResult.confidence 
        
        } else {
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.displayClassifierResults()
        }
    }
    
    // Show the classification results in the UI.
    private func displayClassifierResults() {
        
        guard !self.identifierString.isEmpty else {
            // No object was classified.
            return
        }
        
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        print(message)
    }
    
}
