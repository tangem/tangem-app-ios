//
//  TangemPayCardActionButtonsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayCardActionButtonsView: View {
    let isFrozen: Bool
    let actionsDisabled: Bool
    let detailsAction: () -> Void
    let freezeAction: () -> Void
    let pinAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TangemMainActionButton(
                title: Localization.tangempayCardDetailsShowDetails,
                icon: DesignSystem.Icons.Card.regular24,
                action: detailsAction
            )
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.cardDetailsShowButton)
            .frame(maxWidth: .infinity)

            TangemMainActionButton(
                title: isFrozen
                    ? Localization.tangemPayFreezeCardUnfreeze
                    : Localization.tangemPayFreezeCardFreeze,
                icon: DesignSystem.Icons.Snowflake.regular24,
                action: freezeAction
            )
            .disabled(actionsDisabled)
            .accessibilityIdentifier(
                isFrozen
                    ? TangemPayAccessibilityIdentifiers.freezeCardRowStateFrozen
                    : TangemPayAccessibilityIdentifiers.freezeCardRowStateActive
            )
            .frame(maxWidth: .infinity)

            TangemMainActionButton(
                title: Localization.tangempayCardDetailsPinCode,
                icon: DesignSystem.Icons.Pincode.regular24,
                action: pinAction
            )
            .disabled(actionsDisabled)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.changePinRow)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: Constants.rowMaxWidth)
    }
}

private extension TangemPayCardActionButtonsView {
    enum Constants {
        static let buttonDiameter: CGFloat = 56
        static let interButtonGap: CGFloat = 46
        static let rowMaxWidth = (buttonDiameter + interButtonGap) * 3
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 32) {
        TangemPayCardActionButtonsView(
            isFrozen: false,
            actionsDisabled: false,
            detailsAction: {},
            freezeAction: {},
            pinAction: {}
        )

        TangemPayCardActionButtonsView(
            isFrozen: true,
            actionsDisabled: false,
            detailsAction: {},
            freezeAction: {},
            pinAction: {}
        )

        TangemPayCardActionButtonsView(
            isFrozen: false,
            actionsDisabled: true,
            detailsAction: {},
            freezeAction: {},
            pinAction: {}
        )
    }
    .padding(.horizontal, DesignSystem.Tokens.Spacing.s500)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
