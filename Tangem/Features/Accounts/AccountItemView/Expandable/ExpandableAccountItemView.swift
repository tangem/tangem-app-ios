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
import TangemAccounts

struct ExpandableAccountItemView<ExpandedView>: View where ExpandedView: View {
    @ObservedObject var viewModel: ExpandableAccountItemViewModel

    let expandedView: () -> ExpandedView

    var body: some View {
        ExpandableItemView(
            onExpandedChange: { isExpanded in
                if isExpanded {
                    Analytics.log(.mainButtonAccountShowTokens)
                } else {
                    Analytics.log(.mainButtonAccountHideTokens)
                }
            },
            collapsedView: {
                CollapsedAccountItemHeaderView(
                    name: viewModel.name,
                    iconData: viewModel.iconData,
                    tokensCount: viewModel.tokensCount,
                    totalFiatBalance: viewModel.totalFiatBalance,
                    priceChange: viewModel.priceChange
                )
            },
            expandedView: {
                if viewModel.isEmptyContent {
                    EmptyContentAccountItemView()
                } else {
                    expandedView()
                }
            },
            expandedViewHeader: {
                ExpandedAccountItemHeaderView(
                    name: viewModel.name,
                    iconData: viewModel.iconData,
                )
            }
        )
        .onAppear(perform: viewModel.onViewAppear)
    }
}

#if DEBUG
#Preview {
    let infoProvider: FakeTokenItemInfoProvider = {
        let walletManagers: [FakeWalletManager] = [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager]
        InjectedValues.setTokenQuotesRepository(FakeTokenQuotesRepository(walletManagers: walletManagers))
        return FakeTokenItemInfoProvider(walletManagers: walletManagers)
    }()

    ZStack {
        Color.gray

        VStack {
            ScrollView {
                ExpandableAccountItemView(
                    viewModel: ExpandableAccountItemViewModel(
                        accountModel: CryptoAccountModelMock(
                            isMainAccount: false,
                            onArchive: { _ in }
                        )
                    ),
                    expandedView: {
                        ForEach(infoProvider.viewModels, id: \.tokenItem.id) { tokenViewModel in
                            Text(tokenViewModel.name)
                                .padding(.bottom, 8)
                        }
                    }
                )
                .padding(16)

                Spacer()
            }
        }
    }
}
#endif
