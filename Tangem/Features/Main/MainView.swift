//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemFoundation
import TangemUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        content
            .onAppear(perform: viewModel.onViewAppear)
            .onDisappear(perform: viewModel.onViewDisappear)
            .onDidAppear(perform: viewModel.onDidAppear)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .ignoresSafeArea(.keyboard)
    }

    private var content: some View {
        MainHorizontalPagingScrollView(
            userWalletPageBuilders: viewModel.pages,
            selectedCardIndex: $viewModel.selectedCardIndex,
            onSelectedCardChanged: viewModel.onPageChange,
            pullToRefreshAction: viewModel.pullToRefresh,
            isPullToRefreshRunning: viewModel.isPullToRefreshRunning,
            scanQRCodeAction: viewModel.openQRScan,
            detailsAction: viewModel.openDetails
        )
    }
}

#Preview {
    let viewModel: MainViewModel = {
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        let coordinator = MainCoordinator()
        let viewModel = MainViewModel(
            coordinator: coordinator,
            mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator),
            pushNotificationsAvailabilityProvider: PushNotificationsAvailabilityProviderStub()
        )

        return viewModel
    }()

    NavigationStack {
        MainView(viewModel: viewModel)
    }
}
