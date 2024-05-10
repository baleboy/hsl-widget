//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Stop: Identifiable {
    
    let name: String
    let code: String
    let id: String
        
    init(id: String, name: String, code: String, distance: Int = 0) {
        self.id = id
        self.name = name
        self.code = code
    }
    
    static var defaultStop: Stop {
        Stop(id: "HSL:1080416", name: "Merisotilaantori", code: "H0421", distance: 315)
    }
}
