//
//  SessionDelegate.swift
//  Leo Useless App
//
//  Created by Leonardo Oliveira on 18/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class ARHandler: NSObject, ARSessionDelegate, ARSCNViewDelegate {
    
    weak var viewController: ViewController?
    var visionClassification: VisionClassification?
    
    var anchorLabels = [UUID: String]()
    
    init(viewController: ViewController, visionClassification: VisionClassification) {
        self.viewController = viewController
        self.visionClassification = visionClassification
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        guard let vision = self.visionClassification else {
            return
        }
        
        guard vision.currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        vision.currentBuffer = frame.capturedImage
        vision.classifyCurrentImage()
    }
    
    // When an anchor is added, provide a SceneKit node for it and set its text to the classification label.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let labelText = anchorLabels[anchor.identifier] else {
            fatalError("missing expected associated label for anchor")
        }
        
        guard let viewController = self.viewController else {
            return
        }
        
        if labelText == "Senna" || labelText == "Bola" || labelText == "Rogerio" {
            
            let url = URL(fileURLWithPath: (Bundle.main.path(forResource: "\(labelText)", ofType: "mp4")!))
            let player = AVPlayer(url: url)
            
            let singleVideo = SCNPlane(width: 1.0, height: 1.0)
            singleVideo.firstMaterial?.diffuse.contents = player
            
            let screenNode = SCNNode(geometry: singleVideo)
            
            screenNode.position.x = -0.25
            screenNode.position.y = 1.0
            screenNode.position.x = 0.0
            
            screenNode.eulerAngles.x = -90.0
            screenNode.eulerAngles.y = 0.0
            screenNode.eulerAngles.z = 112.5
            
            viewController.sceneView.scene.rootNode.addChildNode(screenNode)
            player.play()
            
        } else if labelText == "SPFC" || labelText == "Ronaldo" || labelText == "Rubinho" || labelText == "Honda" || labelText == "Paddock" {
            // Montagem
            
        } else if labelText == "Ferrari" || labelText == "Fender" {
            // Audio
            
        } else if labelText == "Stock" || labelText == "Massa" {
            // 3D
            
        } else {
            
        }
        
    }
    
    // MARK: - AR Session Handling
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        guard let viewController = self.viewController else {
            return
        }
        
        viewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            viewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            viewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Filter out optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
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
    
    func restartSession() {
        
        guard let viewController = self.viewController else {
            return
        }
        
        viewController.titleMessage("Reiniciando sessão...")

        anchorLabels = [UUID: String]()
        
        let configuration = ARWorldTrackingConfiguration()
        viewController.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func displayErrorMessage(title: String, message: String) {
        
        guard let viewController = self.viewController else {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Reiniciando sessão", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.restartSession()
        }
        alertController.addAction(restartAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
}
