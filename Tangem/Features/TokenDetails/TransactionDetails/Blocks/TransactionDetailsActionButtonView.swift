//
//  TransactionDetailsActionButtonView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransactionDetailsActionButtonViewData: Equatable {
    enum Style: Equatable {
        case `default`
        case secondary
    }

    let title: String
    let icon: ImageType?
    let style: Style
    let action: TransactionDetailsViewModel.ViewAction
}

struct TransactionDetailsActionButtonView: View {
    let data: TransactionDetailsActionButtonViewData
    let onTap: () -> Void

    var body: some View {
        TangemUI.Button(
            label: data.title,
            accessibilityLabel: data.title,
            action: onTap
        )
        .iconEnd(data.icon)
        .styleType(styleType)
        .size(.x12)
        .horizontalLayout(.infinity)
    }

    private var styleType: TangemUI.Button.StyleType {
        switch data.style {
        case .default: .default
        case .secondary: .secondary
        }
    }
}

// MARK: - Previews

#Preview("Action button") {
    VStack(spacing: 16) {
        TransactionDetailsActionButtonView(
            data: .init(title: "Go to provider", icon: DesignSystem.Icons.ArrowTopRight.regular20, style: .default, action: .close),
            onTap: {}
        )
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
