//
//  MarketsCommonWidgetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsCommonWidgetHeaderView: View {
    let headerTitle: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoading: Bool

    private var isDisplayButton: Bool {
        buttonTitle != nil && !isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: .zero) {
                Text(headerTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .lineLimit(1)
                    .skeletonable(isShown: isLoading)

                Spacer(minLength: 8)

                if isDisplayButton {
                    buttonView
                }
            }
        }
        .padding(.vertical, Layout.Container.verticalPadding)
        .padding(.horizontal, Layout.Container.horizontalPadding)
    }

    private var buttonView: some View {
        Button {
            buttonAction?()
        } label: {
            HStack(alignment: .center, spacing: Layout.ButtonView.contentSpacing) {
                Text(buttonTitle ?? "")
                    .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
            }
            .defaultRoundedBackground(
                with: Colors.Button.secondary,
                verticalPadding: Layout.ButtonView.verticalPadding,
                horizontalPadding: Layout.ButtonView.horizontalPadding,
                cornerRadius: Layout.ButtonView.cornerRadius,
            )
        }
    }
}

extension MarketsCommonWidgetHeaderView {
    enum Layout {
        enum Container {
            static let minHorizontalSpacing: CGFloat = 8.0
            static let horizontalPadding: CGFloat = 8.0
            static let verticalPadding: CGFloat = 8.0
        }

        enum ButtonView {
            /// 20
            static let iconSize: CGFloat = 20

            /// 4
            static let verticalPadding: CGFloat = 4

            /// 6
            static let horizontalPadding: CGFloat = 6

            /// 4
            static let contentSpacing: CGFloat = 4

            /// 14
            static let cornerRadius: CGFloat = 14
        }
    }
}
