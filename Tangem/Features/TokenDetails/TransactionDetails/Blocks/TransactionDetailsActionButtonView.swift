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
    enum Style: Equatable {
        case `default`
        case secondary
    }

    let title: String
    let icon: ImageType?
    let style: Style
    @IgnoredEquatable var handler: () -> Void

    init(title: String, icon: ImageType?, style: Style = .default, handler: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.handler = handler
    }
}

struct TransactionDetailsActionButtonView: View {
    let data: TransactionDetailsActionButtonViewData

    var body: some View {
        TangemUI.Button(
            label: data.title,
            accessibilityLabel: data.title,
            action: data.handler
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
        TransactionDetailsActionButtonView(data: .init(title: "Go to provider", icon: DesignSystem.Icons.ArrowTopRight.regular20, handler: {}))
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
