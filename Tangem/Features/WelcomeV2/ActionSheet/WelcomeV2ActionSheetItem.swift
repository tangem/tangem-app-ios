//
//  WelcomeV2ActionSheetItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct WelcomeV2ActionSheetItem: Identifiable {
    let id: String
    let icon: ImageType?
    let title: String
    let subtitle: String?
    let state: State
    let action: () -> Void

    enum State {
        case enabled
        case loading
        case disabled
    }
}
