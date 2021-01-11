//
//  TapWarning.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WarningPriority: String, Decodable {
    case info, warning, critical
}

enum WarningType: String, Decodable {
    case temporary, permanent
    
    var isWithAction: Bool {
        self == .temporary
    }
}

enum WarningsLocation: String, Decodable {
    case main, send
}

struct TapWarning: Decodable, Hashable {
    let title: String
    let message: String
    let priority: WarningPriority
    
    var type: WarningType = .permanent
    var location: [WarningsLocation] = [.main]
    
    // Warning settings
    var blockchains: [String]?
    var event: WarningEvent?
    
    init(title: String, message: String, priority: WarningPriority, type: WarningType = .permanent,
         location: [WarningsLocation] = [.main], blockchains: [String]? = nil, event: WarningEvent? = nil) {
        self.title = title
        self.message = message
        self.priority = priority
        self.type = type
        self.location = location
        self.blockchains = blockchains
        self.event = event
    }
    
    init(from remote: RemoteTapWarning) {
        title = remote.title
        message = remote.message
        priority = remote.priority
        if let type = remote.type {
            self.type = type
        }
        if let location = remote.location {
            self.location = location
        }
        blockchains = remote.blockchains
    }
    
    static func fetch(remote: [RemoteTapWarning]) -> [TapWarning] {
        remote.map { TapWarning(from: $0) }
    }
}

struct RemoteTapWarning: Decodable {
    let title: String
    let message: String
    let priority: WarningPriority
    
    var type: WarningType?
    var location: [WarningsLocation]?
    
    // Warning settings
    var blockchains: [String]?
}
