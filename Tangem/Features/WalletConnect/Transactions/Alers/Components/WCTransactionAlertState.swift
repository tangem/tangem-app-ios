//
//  WCTransactionAlertState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCTransactionAlertState: Equatable {
    let title: String
    let subtitle: String
    let icon: Icon
    let primaryButton: ButtonSettings
    let secondaryButton: ButtonSettings
    let tangemIcon: MainButton.Icon?
    let needsHoldToConfirm: Bool

    struct Icon: Equatable {
        let asset: ImageType
        let color: Color
    }

    struct ButtonSettings: Equatable {
        let title: String
        let style: MainButton.Style
        let isLoading: Bool
    }
}

extension WCTransactionAlertState {
    init(from state: WCTransactionAlertState, isLoading: Bool) {
        title = state.title
        subtitle = state.subtitle
        icon = state.icon
        primaryButton = state.primaryButton
        secondaryButton = .init(
            title: state.secondaryButton.title,
            style: state.secondaryButton.style,
            isLoading: isLoading
        )
        tangemIcon = state.tangemIcon
        needsHoldToConfirm = state.needsHoldToConfirm
    }
}
