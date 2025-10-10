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
        StoriesView(viewModel: viewModel.storiesModel)
            .alert(item: $viewModel.error, content: { $0.alert })
            .confirmationDialog(viewModel: $viewModel.confirmationDialog)
            .environment(\.colorScheme, .dark)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
    }
}

struct WelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel(coordinator: WelcomeCoordinator(), storiesModel: .init()))
    }
}
