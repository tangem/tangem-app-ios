//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    @ObservedObject var viewModel: TokenItemViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            HStack(alignment: .center, spacing: 12) {
                leadingComponent

                middleComponent

                Spacer()

                trailingComponent
            }
        }
        .padding(14)
    }

    @ViewBuilder
    var leadingComponent: some View {
        TokenIcon(
            name: viewModel.name,
            imageURL: viewModel.imageURL,
            blockchainIconName: viewModel.blockchainIconName,
            size: .init(width: 36, height: 36)
        )
        .saturation(viewModel.networkUnreachable ? 0 : 1)
    }

    @ViewBuilder
    var middleComponent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(viewModel.name)
                    .style(
                        Fonts.Bold.subheadline,
                        color: viewModel.networkUnreachable ? Colors.Text.tertiary : Colors.Text.primary1
                    )

                if viewModel.hasPendingTransactions {
                    Assets.pendingTxIndicator.image
                }
            }

            if !viewModel.networkUnreachable {
                LoadableTextView(
                    state: viewModel.balanceCrypto,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 52, height: 12),
                    loaderTopPadding: 4
                )
            }
        }
    }

    @ViewBuilder
    var trailingComponent: some View {
        VStack(alignment: .trailing) {
            if viewModel.networkUnreachable {
                Text(Localization.commonUnreachable)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            } else {
                LoadableTextView(
                    state: viewModel.balanceFiat,
                    font: Fonts.Regular.subheadline,
                    textColor: Colors.Text.primary1,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 4
                )

                LoadableTextView(
                    state: viewModel.changePercentage,
                    font: Fonts.Regular.footnote,
                    textColor: Colors.Text.tertiary,
                    loaderSize: .init(width: 40, height: 12),
                    loaderTopPadding: 6
                )
            }
        }
    }
}

struct TokenItemView_Previews: PreviewProvider {
    static let infoProvider = FakeTokenItemInfoProvider()

    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(infoProvider.viewModels, id: \.id) { model in
                TokenItemView(viewModel: model)
            }
        }
    }
}
