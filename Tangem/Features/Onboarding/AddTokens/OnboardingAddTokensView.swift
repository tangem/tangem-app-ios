//
//  OnboardingAddTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUIUtils
import TangemUI
import TangemFoundation
import TangemAssets

struct OnboardingAddTokensView: View {
    @ObservedObject var viewModel: OnboardingAddTokensViewModel

    @State private var contentOffset: CGPoint = .zero

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CustomSearchBar(searchText: $viewModel.searchText, placeholder: Localization.commonSearch)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                if contentOffset.y > 0 {
                    Divider()
                }

                if let manageTokensListViewModel = viewModel.manageTokensListViewModel {
                    ManageTokensListView(viewModel: manageTokensListViewModel)
                        .addContentOffsetObserver($contentOffset)
                } else {
                    Spacer()
                    ActivityIndicatorView(style: .large, color: UIColor(Colors.Text.primary1))
                    Spacer()
                }
            }

            VStack {
                Spacer()

                MainButton(settings: viewModel.buttonSettings)
                    .padding(.bottom, 6)
                    .padding(.horizontal, 16)
                    .background(
                        ListFooterOverlayShadowView()
                            .padding(.top, -30)
                    )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardType(.alphabet)
    }
}

#Preview {
    let fakeModel = FakeUserWalletModel.wallet3Cards
    let fakeAPIService = FakeTangemApiService()
    InjectedValues[\.tangemApiService] = fakeAPIService

    return OnboardingAddTokensView(
        viewModel: OnboardingAddTokensViewModel(
            input: .init(
                accountModelsManager: AccountModelsManagerMock(),
                existingCurves: fakeModel.config.existingCurves,
                supportedBlockchains: fakeModel.config.supportedBlockchains,
                hardwareLimitationUtil: HardwareLimitationsUtil(config: fakeModel.config),
                analyticsSourceRawValue: "preview"
            ),
            delegate: nil
        )
    )
}
