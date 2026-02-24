//
//  TangemMainActionButton+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension TangemMainActionButton {
    enum ButtonState {
        case normal
        case disabled

        var isNormal: Bool {
            self == .normal
        }
    }
}
