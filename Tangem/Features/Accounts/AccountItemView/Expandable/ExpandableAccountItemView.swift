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
            collapsedView: {
                AccountItemView(viewModel: viewModel.accountItemViewModel)
            },
            expandedView: expandedView,
            expandedViewHeader: {
                HStack(spacing: 6) {
                    AccountIconView(data: viewModel.accountItemViewModel.iconData)
                        .settings(.smallSized)

                    Text(viewModel.accountItemViewModel.name)
                        .style(Fonts.BoldStatic.caption1, color: Colors.Text.primary1)

                    Spacer()

                    Assets.Accounts.minimize.image
                }
            }
        )
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
                        accountItemViewModel:
                        AccountItemViewModel(
                            accountModel: CryptoAccountModelMock(
                                isMainAccount: false
                            )
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
