//
//  TransactionDetailsActionButtonView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemFoundation

struct TransactionDetailsActionButtonViewData: Equatable {
    let title: String
    let icon: ImageType?
    @IgnoredEquatable var handler: () -> Void
}

struct TransactionDetailsActionButtonView: View {
    let data: TransactionDetailsActionButtonViewData

    var body: some View {
        TangemButtonV2(
            label: AttributedString(data.title),
            iconEnd: data.icon,
            accessibilityLabel: data.title,
            action: data.handler
        )
        .styleType(.default)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Action button") {
    VStack(spacing: 16) {
        TransactionDetailsActionButtonView(data: .init(title: "Go to provider", icon: Assets.arrowRightUpMini, handler: {}))
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
#endif // DEBUG
