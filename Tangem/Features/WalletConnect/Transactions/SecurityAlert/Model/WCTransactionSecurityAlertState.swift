//
//  WCTransactionSecurityAlertState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCTransactionSecurityAlertState: Equatable {
    let title: String
    let subtitle: String
    let icon: Icon
    let primaryButton: ButtonSettings
    let secondaryButton: ButtonSettings

    struct Icon: Equatable {
        let asset: ImageType
        let color: Color
    }

    struct ButtonSettings: Equatable {
        let title: String
        let style: MainButton.Style
    }
}
