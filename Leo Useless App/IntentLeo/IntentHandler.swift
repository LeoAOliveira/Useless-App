//
//  IntentHandler.swift
//  IntentLeo
//
//  Created by Leonardo Oliveira on 21/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        
        return FutebolHandler()
    }
    
}
