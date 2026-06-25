//
//  WelcomeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel

    var body: some View {
        StoriesView(viewModel: viewModel.storiesModel, scanTroubleshootingDialog: $viewModel.scanTroubleshootingDialog)
            .alert(item: $viewModel.error, content: { $0.alert })
            .environment(\.colorScheme, .dark)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
    }
}

#Preview {
    WelcomeView(viewModel: WelcomeViewModel(coordinator: WelcomeCoordinator(), storiesModel: .init()))
}
