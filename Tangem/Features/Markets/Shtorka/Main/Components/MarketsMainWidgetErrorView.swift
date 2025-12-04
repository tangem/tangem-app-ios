//
//  MarketsMainWidgetErrorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct MarketsMainWidgetErrorView: View {
    let tryLoadAgain: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: Layout.contentSpacing) {
            Text(Localization.commonError)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            Button(action: tryLoadAgain) {
                Text(Localization.alertButtonTryAgain)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            }
            .defaultRoundedBackground(
                with: Colors.Button.secondary,
                verticalPadding: Layout.buttonVerticalPadding,
                horizontalPadding: Layout.buttonHorizontalPadding,
                cornerRadius: Layout.buttonCornerRadius
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero, horizontalPadding: .zero)
    }
}

private extension MarketsMainWidgetErrorView {
    enum Layout {
        static let contentSpacing: CGFloat = 8.0
        static let verticalPadding: CGFloat = 16.0
        static let horizontalPadding: CGFloat = 16.0

        static let buttonVerticalPadding: CGFloat = 6.0
        static let buttonHorizontalPadding: CGFloat = 10.0
        static let buttonCornerRadius: CGFloat = 14.0
    }
}
