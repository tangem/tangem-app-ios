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
    let expandedView: ExpandedView

    init(viewModel: ExpandableAccountItemViewModel, @ViewBuilder expandedView: () -> ExpandedView) {
        self.viewModel = viewModel
        self.expandedView = expandedView()
    }

    @Namespace private var namespace

    // MARK: - Body

    var body: some View {
        let effects = AccountGeometryEffects(namespace: namespace)

        ExpandableItemView(
            isExpanded: viewModel.isExpanded,
            backgroundGeometryEffect: effects.background,
            expandedViewTransition: viewModel.isEmptyContent ? nil : Constants.expandedContentTransition,
            collapsedView: {
                CollapsedAccountItemHeaderView(
                    name: viewModel.name,
                    iconData: viewModel.iconData,
                    tokensCount: viewModel.tokensCount,
                    totalFiatBalance: viewModel.totalFiatBalance,
                    priceChange: viewModel.priceChange,
                    iconGeometryEffect: effects.icon,
                    iconBackgroundGeometryEffect: effects.iconBackground,
                    nameGeometryEffect: effects.name,
                    tokensCountGeometryEffect: effects.tokensCount,
                    balanceGeometryEffect: effects.balance
                )
            },
            expandedView: {
                if viewModel.isEmptyContent {
                    EmptyContentAccountItemView()
                } else {
                    expandedView
                }
            },
            expandedViewHeader: {
                ExpandedAccountItemHeaderView(
                    name: viewModel.name,
                    iconData: viewModel.iconData,
                    totalFiatBalance: viewModel.totalFiatBalance,
                    iconGeometryEffect: effects.icon,
                    iconBackgroundGeometryEffect: effects.iconBackground,
                    nameGeometryEffect: effects.name,
                    tokensCountGeometryEffect: effects.tokensCount,
                    balanceGeometryEffect: effects.balance
                )
            },
            onExpandedChange: viewModel.onExpandedChange
        )
        .onAppear(perform: viewModel.onViewAppear)
    }
}

// MARK: - Constants

private extension ExpandableAccountItemView {
    enum Constants {
        static var expandedContentTransition: AnyTransition {
            .asymmetric(
                insertion: .offset(y: 20).combined(with: .opacity),
                removal: .opacity
            )
        }
    }
}

// MARK: - Previews

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
                Group {
                    ExpandableAccountItemView(
                        viewModel: ExpandableAccountItemViewModel(
                            accountModel: CryptoAccountModelMock(
                                isMainAccount: true,
                                onArchive: { _ in }
                            ),
                            stateStorage: ExpandableAccountItemStateStorageStub(isExpanded: true)
                        ),
                        expandedView: {
                            ForEach(infoProvider.viewModels, id: \.tokenItem.id) { tokenViewModel in
                                Text(tokenViewModel.name)
                                    .padding(.bottom, 8)
                            }
                        }
                    )

                    ExpandableAccountItemView(
                        viewModel: ExpandableAccountItemViewModel(
                            accountModel: CryptoAccountModelMock(
                                isMainAccount: false,
                                onArchive: { _ in }
                            ),
                            stateStorage: ExpandableAccountItemStateStorageStub(isExpanded: false)
                        ),
                        expandedView: {
                            ForEach(infoProvider.viewModels, id: \.tokenItem.id) { tokenViewModel in
                                Text(tokenViewModel.name)
                                    .padding(.bottom, 8)
                            }
                        }
                    )
                }
                .padding(16)

                Spacer()
            }
        }
    }
}
#endif
