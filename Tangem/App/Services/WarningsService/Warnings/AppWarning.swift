//
//  AppWarning.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WarningPriority: String, Decodable {
    case info
    case warning
    case critical
}

enum WarningType: String, Decodable {
    case temporary
    case permanent

    var isWithAction: Bool {
        self == .temporary
    }
}

enum WarningsLocation: String, Decodable {
    case main
    case send
    case manageTokens
}

struct AppWarning: Identifiable, Equatable, Hashable {
    let id: UUID = .init()
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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppWarning, rhs: AppWarning) -> Bool {
        lhs.id == rhs.id
    }
}
