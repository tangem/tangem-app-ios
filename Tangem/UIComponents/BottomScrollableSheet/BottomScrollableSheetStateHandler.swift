//
//  BottomScrollableSheetStateHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BottomScrollableSheetStateHandler {
    func update(state: BottomScrollableSheetStateHandlerState)
}

enum BottomScrollableSheetStateHandlerState {
    case collapsed
    case expanded
}
