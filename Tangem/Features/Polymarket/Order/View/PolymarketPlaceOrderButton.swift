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
    let signing: PolymarketOrderSigningMethod
    let signingButtonType: SigningActionButtonViewType
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: (PolymarketOrderSigningMethod) -> Void

    var body: some View {
        switch rendering {
        case .sessionKey(let button):
            button
                .size(.x12)
                .horizontalLayout(.infinity)
        case .card(let button):
            button
        }
    }
}

// MARK: - Footer content

extension PolymarketPlaceOrderButton {
    var footerContent: FooterContent {
        switch rendering {
        case .sessionKey(let button):
            .buttons(primary: button)
        case .card(let button):
            .signingButton(button)
        }
    }
}

// MARK: - Rendering

private extension PolymarketPlaceOrderButton {
    enum Rendering {
        case sessionKey(TangemUI.Button)
        case card(SigningActionButtonView)
    }

    var rendering: Rendering {
        let tap = { action(signing) }

        switch signing {
        case .sessionKey:
            return .sessionKey(
                TangemUI.Button(label: title, accessibilityLabel: title, action: tap)
                    .styleType(.primary)
                    .loading(.spinner(if: isLoading))
                    .enabled(!isDisabled)
            )
        case .ownerKey:
            return .card(
                SigningActionButtonView(type: signingButtonType, title: title, isLoading: isLoading, isDisabled: isDisabled, action: tap)
            )
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        PolymarketPlaceOrderButton(
            signing: .sessionKey,
            signingButtonType: .requiredNFCInteraction,
            title: "Place order",
            isLoading: false,
            isDisabled: false,
            action: { _ in }
        )

        PolymarketPlaceOrderButton(
            signing: .ownerKey,
            signingButtonType: .requiredNFCInteraction,
            title: "Place order",
            isLoading: false,
            isDisabled: false,
            action: { _ in }
        )
    }
    .padding(16)
}
