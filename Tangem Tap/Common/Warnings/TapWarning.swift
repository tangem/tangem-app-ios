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
    
    var backgroundColor: Color {
        switch self {
        case .info: return .tangemTapGrayDark6
        case .warning: return .tangemTapWarning
        case .critical: return .tangemTapCritical
        }
    }
    
    var messageColor: Color {
        switch self {
        case .info: return .tangemTapGrayDark
        default: return .white
        }
    }
}

enum WarningType: String, Decodable {
    case temporary, permanent
    
    var isWithAction: Bool {
        self == .temporary
    }
}

struct TapWarning: Decodable, Hashable {
    let title: String
    let message: String
    let priority: WarningPriority
    let type: WarningType
    
    internal init(title: String, message: String, priority: WarningPriority, type: WarningType) {
        self.title = title
        self.message = message
        self.priority = priority
        self.type = type
    }
    
}
