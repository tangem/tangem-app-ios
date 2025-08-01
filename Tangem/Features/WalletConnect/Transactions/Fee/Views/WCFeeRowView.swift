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
        HStack(spacing: 0) {
            leadingView
                .padding(.trailing, 8)

            Spacer()

            trailingView
                .lineLimit(1)
                .padding(.trailing, 2)

            Assets.Glyphs.selectIcon.image
                .foregroundStyle(Colors.Icon.informative)
        }
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
        case .loaded(let components):
            trailingView(for: components)
        case .failedToLoad:
            Text(AppConstants.emDashSign)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .layoutPriority(1)
        }
    }

    func trailingView(for components: FormattedFeeComponents) -> some View {
        Text("~ " + (components.fiatFee ?? components.cryptoFee))
            .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            .layoutPriority(1)
    }
}
