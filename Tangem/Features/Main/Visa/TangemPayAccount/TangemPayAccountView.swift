//
//  TangemPayAccountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization
import TangemVisa

struct TangemPayAccountView: View {
    @ObservedObject var viewModel: TangemPayAccountViewModel

    var body: some View {
        Button(action: viewModel.userDidTapView) {
            HStack(alignment: .center, spacing: 12) {
                leadingContent

                Spacer()

                trailingContent
            }
            .opacity(viewModel.state.isFullyVisible ? 1 : 0.6)
            .defaultRoundedBackground(with: Colors.Background.primary, verticalPadding: 14, horizontalPadding: 14)
        }
    }

    @ViewBuilder
    var leadingContent: some View {
        if viewModel.state.isSkeleton {
            skeletonLeadingContent
        } else {
            defaultLeadingContent
        }
    }

    @ViewBuilder
    var skeletonLeadingContent: some View {
        HStack(alignment: .center, spacing: 12) {
            skeleton(width: 36, height: 36, radius: 8)

            VStack(alignment: .leading, spacing: 8) {
                skeleton(width: 112)
                skeleton(width: 80)
            }
        }
    }

    @ViewBuilder
    var defaultLeadingContent: some View {
        HStack(alignment: .center, spacing: 12) {
            Assets.Visa.accountAvatar.image
                .resizable()
                .frame(width: 36, height: 36)
                .aspectRatio(contentMode: .fit)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayPaymentAccount)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.state.subtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    var trailingContent: some View {
        switch viewModel.state {
        case .kycInProgress, .issuingYourCard, .syncNeeded, .unavailable, .rootedDevice, .kycDeclined:
            EmptyView()

        case .failedToIssueCard:
            Assets.redCircleWarning20Outline.image

        case .normal(_, let balance):
            VStack(alignment: .trailing, spacing: 4) {
                LoadableTokenBalanceView(
                    state: balance,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: .init(size: CGSize(width: 40, height: 17))
                )

                SensitiveText(TangemPayUtilities.usdcTokenItem.currencySymbol)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

        case .skeleton:
            VStack(alignment: .trailing, spacing: 8) {
                skeleton(width: 40)
                skeleton(width: 40)
            }
        }
    }

    private func skeleton(
        width: CGFloat,
        height: CGFloat = Constants.defaultSkeletonHeight,
        radius: CGFloat = Constants.defaultSkeletonRadius
    ) -> some View {
        SkeletonView()
            .frame(width: width, height: height)
            .cornerRadiusContinuous(radius)
    }
}

// MARK: - TangemPayAccountView+Constants

private extension TangemPayAccountView {
    enum Constants {
        static let defaultSkeletonHeight: CGFloat = 12
        static let defaultSkeletonRadius: CGFloat = 3
    }
}
