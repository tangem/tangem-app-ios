//
//  WCFeeRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization

struct WCFeeRowView: View {
    let viewModel: WCFeeRowViewModel

    var body: some View {
        Button(action: viewModel.onTap) {
            HStack(spacing: 0) {
                leadingView

                Spacer(minLength: 8)

                trailingView
                    .lineLimit(1)
                    .padding(.trailing, 2)

                Assets.Glyphs.selectIcon.image
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var leadingView: some View {
        HStack(spacing: 8) {
            Assets.Glyphs.feeNew.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(Colors.Icon.accent)

            Text(Localization.commonNetworkFeeTitle)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.components {
        case .loading:
            SkeletonView()
                .frame(width: 70, height: 15)
                .cornerRadius(4, corners: .allCorners)

        case .success(let components):
            Text(formattedFee(components: components))
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .layoutPriority(1)

        case .failure:
            Text(AppConstants.emDashSign)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .layoutPriority(1)
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func formattedFee(components: FormattedFeeComponents) -> String {
        let feeString = components.fiatFee ?? components.cryptoFee

        return feeString.starts(with: "<") || feeString.starts(with: ">")
            ? feeString
            : "\(AppConstants.tildeSign) \(feeString)"
    }
}
