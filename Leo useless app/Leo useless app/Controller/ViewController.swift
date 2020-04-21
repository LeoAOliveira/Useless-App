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

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    enum MessageType {
        case trackingStateEscalation
        case planeEstimation
        case contentPlacement
        case focusSquare
        
        static var all: [MessageType] = [
            .trackingStateEscalation,
            .planeEstimation,
            .contentPlacement,
            .focusSquare
        ]
    }

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var roundedBlurView: UIVisualEffectView!
    
    private var arHandler: ARHandler?
    private var visionClassification: VisionClassification?
    private var timers: [MessageType: Timer] = [:]
    var restartExperienceHandler: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        visionClassification = VisionClassification(viewController: self)
        
        guard let vision = visionClassification else {
            return
        }
        
        arHandler = ARHandler(viewController: self, visionClassification: vision)
        sceneView.delegate = arHandler
        sceneView.session.delegate = arHandler
        
        blurView.layer.cornerRadius = 10.0
        roundedBlurView.layer.cornerRadius = 25.0
        
        blurView.clipsToBounds = true
        roundedBlurView.clipsToBounds = true
        
        // Hook up status view controller callback.
        restartExperienceHandler = { [unowned self] in
            self.arHandler?.restartSession()
        }
        
        subtitleLabel.text = "Procurando..."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        // configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Message Handling
    
    func titleMessage(_ text: String) {
        titleLabel.text = text
    }
    
    func subtitleMessage(_ text: String) {
        subtitleLabel.text = text
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] timer in
            self?.titleMessage(text)
            timer.invalidate()
        })
        
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(`for` messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessages() {
        for messageType in MessageType.all {
            cancelScheduledMessage(for: messageType)
        }
    }
    
    // MARK: - ARKit
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        titleMessage(trackingState.presentationString)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [unowned self] _ in
            self.cancelScheduledMessage(for: .trackingStateEscalation)
            
            if let recommendation = trackingState.recommendation {
                self.subtitleMessage(recommendation)
            }
        })
        
        timers[.trackingStateEscalation] = timer
    }
    
    // MARK: - IBActions
    
    @IBAction private func restartExperience(_ sender: UIButton) {
        restartExperienceHandler()
    }
    
    @IBAction func placeExperienceAtLocation(_ sender: UITapGestureRecognizer) {
        
        guard let arHandler = self.arHandler , let vision = self.visionClassification else {
            return
        }
        
        let hitLocationInView = sender.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(hitLocationInView, types: [.featurePoint, .estimatedHorizontalPlane])
        if let result = hitTestResults.first {
            
            // Add a new anchor at the tap location.
            let anchor = ARAnchor(transform: result.worldTransform)
            sceneView.session.add(anchor: anchor)
            
            // Track anchor ID to associate text with the anchor after ARKit creates a corresponding SKNode.
            arHandler.anchorLabels[anchor.identifier] = vision.identifierString
        }
    }
    
}

extension ARCamera.TrackingState {
    
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "Tracking indisponível"
        case .normal:
            return "Tracking normal"
        case .limited(.excessiveMotion):
            return "Excesso de movimento"
        case .limited(.insufficientFeatures):
            return "Poucos detalhes"
        case .limited(.initializing):
            return "Inicializando..."
        case .limited(.relocalizing):
            return "Recuperando de interupção"
        default:
            return "Tracking indisponível"
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        case .limited(.relocalizing):
            return "Return to the location where you left off or try resetting the session."
        default:
            return nil
        }
    }
}
