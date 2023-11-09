//
//  WelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
//        storiesView
//            .alert(item: $viewModel.error, content: { $0.alert })
//            .onAppear(perform: viewModel.onAppear)
//            .onDidAppear(viewModel.onDidAppear)
//            .onDisappear(perform: viewModel.onDisappear)
//            .background(
//                ScanTroubleshootingView(
//                    isPresented: $viewModel.showTroubleshootingView,
//                    tryAgainAction: viewModel.tryAgain,
//                    requestSupportAction: viewModel.requestSupport
//                )
//            )
//        GroupedScrollView {
        SendAmountContainerView(
            viewModel: viewModel.sendAmountContainerViewModel,
//            decimalValue: $viewModel.decimalValue,
            toggle: $viewModel.toggle
        )
//        }
//        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
//        DecimalNumberTextField(decimalValue: $viewModel.decimalValue, decimalNumberFormatter: .init(maximumFractionDigits: 3))
    }

    var storiesView: some View {
        StoriesView(viewModel: viewModel.storiesModel) { [weak viewModel] in
            if let viewModel = viewModel {
                viewModel.storiesModel.currentStoryPage(
                    isScanning: $viewModel.isScanningCard,
                    scanCard: viewModel.scanCardTapped,
                    orderCard: viewModel.orderCard,
                    openPromotion: viewModel.openPromotion,
                    searchTokens: viewModel.openTokensList
                )
            }
        }
        .statusBar(hidden: true)
        .environment(\.colorScheme, viewModel.storiesModel.currentPage.colorScheme)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel(shouldScanOnAppear: false, coordinator: WelcomeCoordinator()))
    }
}
