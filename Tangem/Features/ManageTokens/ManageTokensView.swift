//
//  ManageTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    @State private var contentOffset: CGPoint = .zero

    private var savingIcon: MainButton.Icon? {
        viewModel.needsCardDerivation ? .trailing(Assets.tangemIcon) : nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CustomSearchBar(searchText: $viewModel.searchText, placeholder: Localization.commonSearch)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if contentOffset.y > 0 {
                    Divider()
                }

                ManageTokensListView(viewModel: viewModel.manageTokensListViewModel, header: customTokensList)
                    .addContentOffsetObserver($contentOffset)
            }

            VStack {
                Spacer()

                MainButton(
                    title: Localization.commonSave,
                    icon: savingIcon,
                    isLoading: viewModel.isSavingChanges,
                    action: viewModel.saveChanges
                )
                .padding(.bottom, 10)
                .padding(.horizontal, 16)
                .background(
                    ListFooterOverlayShadowView()
                        .padding(.top, -30)
                )
                .hidden(viewModel.isPendingListEmpty)
                .animation(.default, value: viewModel.isPendingListEmpty)
            }
        }
        .background(Colors.Background.primary.ignoresSafeArea())
        .navigationTitle(Text(Localization.addTokensTitle))
        .scrollDismissesKeyboard(.immediately)
        .keyboardType(.alphabet)
        .bindAlert($viewModel.alert)
        .if(viewModel.canAddCustomToken) {
            $0.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: {
                            viewModel.openAddCustomToken()
                        }, label: {
                            Assets.plus24.image
                                .foregroundStyle(Colors.Icon.primary1)
                        }
                    )
                }
            }
        }
    }

    private func customTokensList() -> some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.customTokensList) { item in
                CustomTokenItemView(
                    info: item,
                    removeAction: { info in
                        viewModel.removeCustomToken(info)
                    }
                )
            }
        }
    }
}

#Preview {
    let fakeModel = FakeUserWalletModel.wallet3Cards
    let fakeAPIService = FakeTangemApiService()
    InjectedValues[\.tangemApiService] = fakeAPIService
    let context = LegacyManageTokensContext(
        userTokensManager: fakeModel.userTokensManager,
        walletModelsManager: fakeModel.walletModelsManager
    )

    let adapter = ManageTokensAdapter(
        settings: .init(
            existingCurves: fakeModel.config.existingCurves,
            supportedBlockchains: fakeModel.config.supportedBlockchains,
            hardwareLimitationUtil: HardwareLimitationsUtil(config: fakeModel.config),
            analyticsSourceRawValue: "preview",
            context: context
        )
    )

    return NavigationStack {
        ManageTokensView(viewModel: .init(
            adapter: adapter,
            context: context,
            coordinator: nil
        ))
    }
}
