//
//  ExpandableAccountItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct ExpandableAccountItemView: View {
    @ObservedObject var viewModel: ExpandableAccountItemViewModel

    var body: some View {
        ExpandableItemView(
            collapsedView: {
                AccountItemView(viewModel: viewModel.accountItemViewModel)
            },
            expandedView: {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.groupedTokens, id: \.0) { section in
                        makeNetworkSection(name: section.name, tokens: section.tokens)
                    }
                }
            },
            expandedViewHeader: {
                HStack(spacing: 6) {
                    accountImageData.image
                        .resizable()
                        .frame(size: .init(bothDimensions: 14))
                        .roundedBackground(with: accountImageData.backgroundColor, padding: 3, radius: 4)

                    Text(viewModel.accountItemViewModel.name)
                        .style(Fonts.BoldStatic.caption1, color: Colors.Text.primary1)

                    Spacer()

                    Assets.Accounts.minimize.image
                }
            }
        )
    }

    private func makeNetworkSection(name: String, tokens: [TokenItemViewModel]) -> some View {
        LazyVStack(alignment: .leading, spacing: .zero) {
            Text(name)
                .style(Fonts.BoldStatic.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 8)

            ForEach(tokens) { token in
                TokenItemView(viewModel: token, cornerRadius: 0)
            }
        }
    }

    private var accountImageData: (backgroundColor: Color, image: Image) {
        viewModel.accountItemViewModel.imageData
    }
}

#if DEBUG
#Preview {
    let infoProvider: FakeTokenItemInfoProvider = {
        let walletManagers: [FakeWalletManager] = [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager]
        InjectedValues.setTokenQuotesRepository(FakeTokenQuotesRepository(walletManagers: walletManagers))
        return FakeTokenItemInfoProvider(walletManagers: walletManagers)
    }()

    return ZStack {
        Color.gray
        VStack {
            ScrollView {
                ExpandableAccountItemView(
                    viewModel: ExpandableAccountItemViewModel(
                        accountItemViewModel: AccountItemViewModel(),
                        tokens: infoProvider.viewModels
                    )
                )
                .padding(16)
                Spacer()
            }
        }
    }
}
#endif
