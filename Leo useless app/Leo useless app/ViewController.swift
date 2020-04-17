//
//  ViewController.swift
//  Leo Useless App
//
//  Created by Leonardo Oliveira on 17/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, UIGestureRecognizerDelegate, ARSKViewDelegate, ARSessionDelegate, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
        
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let overlayScene = SKScene()
        overlayScene.scaleMode = .aspectFill
        
        sceneView.delegate = self
        sceneView.session.delegate = self
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }

    var currentBuffer: CVPixelBuffer?

    let visionQueue = DispatchQueue(label: "LeonardoAOliveira.Leo-Useless-App")
    
    func classifyCurrentImage() {
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue)) else { 
            return
        }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    
    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]
        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            let label = bestResult.identifier.split(separator: ",").first {
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

    func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            return // No object was classified.
        }
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)
    }
        
    var anchorLabels = [UUID: String]()

        func placeLabelAtLocation(sender: UITapGestureRecognizer) {
        let hitLocationInView = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(hitLocationInView, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = hitTestResults.first {
            
            let anchor = ARAnchor(transform: result.worldTransform)
            sceneView.session.add(anchor: anchor)
            
            anchorLabels[anchor.identifier] = identifierString
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        setOverlaysHidden(true)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }

    func setOverlaysHidden(_ shouldHide: Bool) {
        sceneView.scene.children.forEach { node in
            if shouldHide {
                node.alpha = 0
                
            } else {
                node.run(.fadeIn(withDuration: 0.5))
            }
        }
    }
}
