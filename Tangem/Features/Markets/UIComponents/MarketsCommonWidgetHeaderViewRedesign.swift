//
//  MarketsCommonWidgetHeaderViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI

struct MarketsCommonWidgetHeaderViewRedesign: View {
    let headerTitle: String
    let headerImage: Image?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoadingState: MarketsCommonWidgetHeaderView.LoadingState

    private var isDisplayButton: Bool {
        return buttonTitle != nil && isLoadingState.isButtonVisibility
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: .zero) {
                Text(headerTitle)
                    .lineLimit(1)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .skeletonable(isShown: isLoadingState.isHeaderSkeletonable)

                if let headerImage = headerImage {
                    FixedSpacer(width: Layout.HeaderImage.spacing)

                    headerImage
                        .resizable()
                        .scaledToFit()
                        .frame(height: Layout.HeaderImage.height)
                        .hidden(isLoadingState.isHeaderSkeletonable)
                }

                Spacer(minLength: 8)

                if isDisplayButton {
                    buttonView
                }
            }
            .padding(.horizontal, Layout.Content.horizontalPadding)
        }
        .padding(.vertical, Layout.Container.verticalPadding)
        .padding(.horizontal, Layout.Container.horizontalPadding)
    }

    private var buttonView: some View {
        Button {
            buttonAction?()
        } label: {
            HStack(spacing: 0) {
                Text(buttonTitle ?? "")
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                Assets.chevron.image
                    .frame(size: .init(bothDimensions: 24))
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSeeAllButton)
    }
}

private extension MarketsCommonWidgetHeaderViewRedesign {
    enum Layout {
        enum Container {
            static let horizontalPadding: CGFloat = 16.0
            static let verticalPadding: CGFloat = 2.0
        }

        enum Content {
            static let horizontalPadding: CGFloat = 8.0
        }

        enum HeaderImage {
            static let spacing: CGFloat = 8.0
            static let height: CGFloat = 20.0
        }
    }
}
