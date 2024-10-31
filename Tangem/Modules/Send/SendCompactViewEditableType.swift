//
//  SendCompactViewEditableType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendCompactViewEditableType {
    case disabled
    case enabled(action: (() -> Void)? = nil)

    var background: Color {
        switch self {
        case .disabled: Colors.Button.disabled
        case .enabled: Colors.Background.action
        }
    }
}
