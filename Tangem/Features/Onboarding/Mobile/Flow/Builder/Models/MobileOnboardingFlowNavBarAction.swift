//
//  MobileOnboardingFlowNavBarAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

enum MobileOnboardingFlowNavBarAction {
    typealias Handler = () -> Void

    case back(handler: Handler)
    case close(style: CloseStyle = .text, handler: Handler)
    case skip(handler: Handler)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .back(let handler):
            NavigationBarButton.back(action: handler)
                .redesigned()
        case .close(let style, let handler):
            makeCloseAction(style: style, handler: handler)
                .padding(.leading, 16)
        case .skip(let handler):
            SwiftUI.Button(action: handler) {
                Text(Localization.commonSkip)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(height: OnboardingLayoutConstants.navbarSize.height)
            }
            .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.accessCodeSkipButton)
            .padding(.trailing, 16)
        }
    }

    @ViewBuilder
    private func makeCloseAction(style: CloseStyle, handler: @escaping Handler) -> some View {
        switch style {
        case .text:
            CloseTextButton(action: handler)
        case .button:
            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: nil,
                action: handler
            )
            .styleType(.material(.glass))
            .size(.x11)
        }
    }
}

// MARK: - Types

extension MobileOnboardingFlowNavBarAction {
    enum CloseStyle {
        case text
        case button
    }
}
