//
//  MarketsNavigationBackButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsNavigationBackButton: View {
    let presentSource: PresentSource
    let action: () -> Void

    var body: some View {
        switch presentSource {
        case .navigation:
            BackButton(
                height: 44.0,
                isVisible: true,
                isEnabled: true,
                hPadding: 10.0,
                action: action
            )
        case .deeplink:
            CloseTextButton(action: action)
                .padding(.leading, 16.0)
        }
    }
}

extension MarketsNavigationBackButton {
    enum PresentSource {
        case navigation
        case deeplink
    }
}
