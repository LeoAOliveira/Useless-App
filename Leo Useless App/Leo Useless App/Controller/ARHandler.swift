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
import AVFoundation

class ARHandler: NSObject, ARSessionDelegate, ARSCNViewDelegate, AVAudioPlayerDelegate {
    
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
        
        guard let sceneView = viewController?.sceneView else {
            return
        }
        
        let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
        
        let rotateTransform = simd_mul(anchor.transform, rotate)
        
        if labelText == "Senna" || labelText == "Bola" || labelText == "Rogerio" {
            
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: labelText, ofType: "mp4")!)
            let player = AVPlayer(url: url)
            
            var width: CGFloat = 0.711
            var height: CGFloat = 0.400
            
            
            if labelText == "Bola" {
                width = 0.536
                height = 0.400
            }
            
            let singleVideo = SCNPlane(width: width, height: height)
            singleVideo.firstMaterial?.diffuse.contents = player
            singleVideo.firstMaterial?.isDoubleSided = true
            
            let screenNode = SCNNode(geometry: singleVideo)
            
            screenNode.position.y = screenNode.position.y + 0.3
            
            screenNode.transform = SCNMatrix4(rotateTransform)
            
            node.addChildNode(screenNode)
            
            player.play()
            
        } else if labelText == "SPFC" || labelText == "Rubinho" || labelText == "Honda" || labelText == "Paddock" {
            
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: labelText, ofType: "mp4")!)
            let player = AVPlayer(url: url)
            
            guard let scene = SCNScene(named: "art.scnassets/room.scn"),
                let container = scene.rootNode.childNode(withName: "container", recursively: false),
                let singleVideo = container.childNode(withName: "singleVideo", recursively: false), 
                let firstImage = container.childNode(withName: "firstImage", recursively: false), 
                let secondImage = container.childNode(withName: "secondImage", recursively: false) else {
                return
            }
            
            singleVideo.geometry?.firstMaterial?.diffuse.contents = player
            singleVideo.geometry?.firstMaterial?.isDoubleSided = true
            
            firstImage.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(labelText)1")
            secondImage.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(labelText)2")
            
            container.transform = SCNMatrix4(rotateTransform)
            
            node.addChildNode(container)            
            player.play()
            
        } else if labelText == "Ronaldo" {
            
            let url1 = URL(fileURLWithPath: Bundle.main.path(forResource: "\(labelText)1", ofType: "mp4")!)
            let player1 = AVPlayer(url: url1)
            
            let url2 = URL(fileURLWithPath: Bundle.main.path(forResource: "\(labelText)2", ofType: "mp4")!)
            let player2 = AVPlayer(url: url2)
            
            guard let scene = SCNScene(named: "art.scnassets/room.scn"),
                let doubleScreen = scene.rootNode.childNode(withName: "doubleScreen", recursively: false),
                let firstVideo = doubleScreen.childNode(withName: "firstVideo", recursively: false), 
                let secondVideo = doubleScreen.childNode(withName: "secondVideo", recursively: false) else {
                return
            }
            
            firstVideo.geometry?.firstMaterial?.diffuse.contents = player1
            firstVideo.geometry?.firstMaterial?.isDoubleSided = true
            
            secondVideo.geometry?.firstMaterial?.diffuse.contents = player2
            secondVideo.geometry?.firstMaterial?.isDoubleSided = true
            
            doubleScreen.transform = SCNMatrix4(rotateTransform)
            
            node.addChildNode(doubleScreen)
            
            player1.play()
            player2.play()
            
        } else if labelText == "Ferrari" || labelText == "Fender" {
            
            guard let source = SCNAudioSource(fileNamed: "\(labelText).mp3") else {
                return
            }
            
            let playAudio = SCNAction.playAudio(source, waitForCompletion: true)
            
            var textString = "\(labelText)"
            
            if labelText == "Ferrari" {
                textString = "Ferrari V12"
            } else {
                textString = "Stratocaster"
            }
            
            let text = SCNText(string: textString, extrusionDepth: 2)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            text.materials = [material]
            
            let textNode = SCNNode()
            node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            textNode.geometry = text
            textNode.transform = SCNMatrix4(rotateTransform)
            
            node.addChildNode(textNode)
            node.runAction(playAudio)
            
        } else if labelText == "Stock" || labelText == "Massa" {
            
            guard let scene = SCNScene(named: "art.scnassets/room.scn"),
                let model = scene.rootNode.childNode(withName: labelText, recursively: false) else {
                return
            }
            
            model.transform = SCNMatrix4(rotateTransform)
            
            node.addChildNode(model)
            
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
