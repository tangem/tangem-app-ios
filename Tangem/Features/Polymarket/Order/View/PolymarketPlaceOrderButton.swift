//
//  PolymarketPlaceOrderButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PolymarketPlaceOrderButton: View {
    let signsWithSessionKey: Bool
    let signingButtonType: SigningActionButtonViewType
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        if signsWithSessionKey {
            Self.sessionKeyButton(title: title, isLoading: isLoading, isDisabled: isDisabled, action: action)
                .size(.x12)
                .horizontalLayout(.infinity)
        } else {
            SigningActionButtonView(type: signingButtonType, title: title, isLoading: isLoading, isDisabled: isDisabled, action: action)
        }
    }
}

// MARK: - Footer content

extension PolymarketPlaceOrderButton {
    static func footerContent(
        signsWithSessionKey: Bool,
        signingButtonType: SigningActionButtonViewType,
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> FooterContent {
        guard signsWithSessionKey else {
            return .signingButton(
                SigningActionButtonView(type: signingButtonType, title: title, isLoading: isLoading, isDisabled: isDisabled, action: action)
            )
        }

        return .buttons(primary: sessionKeyButton(title: title, isLoading: isLoading, isDisabled: isDisabled, action: action))
    }
}

// MARK: - Session key button

private extension PolymarketPlaceOrderButton {
    static func sessionKeyButton(title: String, isLoading: Bool, isDisabled: Bool, action: @escaping () -> Void) -> TangemUI.Button {
        TangemUI.Button(label: title, accessibilityLabel: title, action: action)
            .styleType(.primary)
            .loading(.spinner(if: isLoading))
            .enabled(!isDisabled)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        PolymarketPlaceOrderButton(
            signsWithSessionKey: true,
            signingButtonType: .requiredNFCInteraction,
            title: "Place order",
            isLoading: false,
            isDisabled: false,
            action: {}
        )

        PolymarketPlaceOrderButton(
            signsWithSessionKey: false,
            signingButtonType: .requiredNFCInteraction,
            title: "Place order",
            isLoading: false,
            isDisabled: false,
            action: {}
        )
    }
    .padding(16)
}
