//
//  SendCompactViewEditableType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

enum SendCompactViewEditableType {
    case enabled(action: (() -> Void)? = nil)
    case disabled

    var editable: Bool {
        switch self {
        case .enabled: true
        case .disabled: false
        }
    }

    var background: Color {
        switch self {
        case .disabled: Colors.Background.action
        case .enabled: Colors.Background.action
        }
    }
}
