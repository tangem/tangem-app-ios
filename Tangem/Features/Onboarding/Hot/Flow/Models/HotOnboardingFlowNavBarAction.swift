//
//  HotOnboardingFlowNavBarAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

enum HotOnboardingFlowNavBarAction {
    typealias Handler = () -> Void

    case back(handler: Handler)
    case close(handler: Handler)
    case skip(handler: Handler)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .back(let handler):
            BackButton(
                height: OnboardingLayoutConstants.navbarSize.height,
                isVisible: true,
                isEnabled: true,
                action: handler
            )
        case .close(let handler):
            CloseButton(dismiss: handler)
                .padding(.leading, 16)
        case .skip(let handler):
            Button(action: handler) {
                Text(Localization.commonSkip)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(height: OnboardingLayoutConstants.navbarSize.height)
            }
            .padding(.trailing, 16)
        }
    }
}
