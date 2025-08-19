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
    case disabled
    case enabled(action: (() -> Void)? = nil)

    var editable: Bool {
        switch self {
        case .enabled: true
        case .disabled: false
        }
    }

    var background: Color {
        switch self {
        case .disabled: Colors.Button.disabled
        case .enabled: Colors.Background.action
        }
    }
}
