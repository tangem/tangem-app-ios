//
//  BottomScrollableSheetState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum BottomScrollableSheetState: Equatable {
    enum Trigger {
        case dragGesture
        case tapGesture
    }

    case top(trigger: Trigger)
    case bottom

    var isBottom: Bool {
        if case .bottom = self {
            return true
        }
        return false
    }
}
