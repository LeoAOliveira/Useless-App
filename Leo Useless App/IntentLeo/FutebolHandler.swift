//
//  FutebolHandler.swift
//  IntentLeo
//
//  Created by Leonardo Oliveira on 21/04/20.
//  Copyright © 2020 Leonardo Oliveira. All rights reserved.
//

import Foundation
import Intents

public class FutebolHandler: NSObject, FutebolIntentHandling {
    
    public func handle(intent: FutebolIntent, completion: @escaping (FutebolIntentResponse) -> Void) {
        
        guard let canto = intent.canto else {
            return
        }
        
        var resultado = ""
        
        if canto.lowercased() == "e o e o" {
            resultado = "Tricolor Tricolor!"
        
        } else if canto.lowercased() == "domingo eu vou lá no morumbi" {
            resultado = "A independente vai invadir. Vou levar foguetes e bandeira não vai ser de brincadeira ele vai ser campeão. Porque eu não, cadeira numerada, eu vou de arquibancada para sentir mais emoção. Porque meu time, bota para piiiii! E o nome deles são vocês quem vão dizer. o o o o. o ooo, o oo oo oo. o oo oo oo. o o São Paulo!"
        
        } else if canto.lowercased() == "sou tricolor" {
            resultado = "Tenho libertadores! Não alugo estádio! Sou Hexa brasileiro! Nunca fui rebaixado!"
        
        } else if canto.lowercased() == "pato marcou gol" {
            resultado = "eeeeeeeeeeeee!"
        
        } else if canto.lowercased() == "Ponte que partiu" {
            resultado = "É o melhor, goleiro do Brasil, Rogério!"
        
        } else if canto.lowercased() == "o le le o la la" {
            resultado = "O Hernanes vem ai e o bicho vai pegar!"
        
        } else if canto.lowercased() == "o o" {
            resultado = "Toca no Calleri que é gol"
        
        } else if canto.lowercased() == "quais os 5 mandamentos do professor" {
            resultado = "1. Toca passa toca passa. 2. Sem chutão. 3. Pressão na saída. 4. Posse de bola. 5. Criar 1479 chances de gol."
        
        } else if canto.lowercased() == "entre bater o penalti e ajudar na briga" {
            resultado = "Eu prefiro, é, ajudar, na, briga."
        
        } else if canto.lowercased() == "raí raí" {
            resultado = "O terror do Morumbi!"
        
        } else if canto.lowercased() == "vai lá vai lá" {
            resultado = "Vai lá, vai lá! Vai lá de coração! Vamos São Paulo, vamos são Paulo, vamos ser campeão!"
        
        } else if canto.lowercased() == "o tricolor" {
            resultado = "O o o o! Clube bem amado! As tuas glórias vem do passado!"
        
        } else {
            resultado = "São Paulo!"
        }
        
        let sucesso = FutebolIntentResponse.success(resposta: String(resultado))
        completion(sucesso)
    }
    
    public func resolveCanto(for intent: FutebolIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let canto = intent.canto {
            completion(INStringResolutionResult.success(with: canto))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    
    
}
