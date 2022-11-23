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
        storiesView
            .navigationBarHidden(viewModel.navigationBarHidden)
            .navigationBarTitle("", displayMode: .inline)
            .alert(item: $viewModel.error, content: { $0.alert })
            .onAppear(perform: viewModel.onAppear)
            .onDidAppear(viewModel.onDidAppear)
            .onDisappear(perform: viewModel.onDisappear)
            .background(
                ScanTroubleshootingView(isPresented: $viewModel.showTroubleshootingView,
                                        tryAgainAction: viewModel.tryAgain,
                                        requestSupportAction: viewModel.requestSupport)
            )
    }

    var storiesView: some View {
        StoriesView(viewModel: viewModel.storiesModel) { // [REDACTED_TODO_COMMENT]
            viewModel.storiesModel.currentStoryPage(
                isScanning: viewModel.isScanningCard,
                scanCard: viewModel.scanCard,
                orderCard: viewModel.orderCard,
                searchTokens: viewModel.openTokensList
            )
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
