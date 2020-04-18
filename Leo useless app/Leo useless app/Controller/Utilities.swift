//
//  Utilities.swift
//  Leo Useless App
//
//  Created by Leonardo Oliveira on 18/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import Foundation
import ARKit

// Convert device orientation to image orientation for use by Vision analysis.
extension CGImagePropertyOrientation {
    
    init(_ deviceOrientation: UIDeviceOrientation) {
        
        switch deviceOrientation {
        case .portraitUpsideDown: 
            self = .left
        case .landscapeLeft: 
            self = .up
        case .landscapeRight: 
            self = .down
        default: 
            self = .right
        }
    }
}
