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
        StoriesView(viewModel: viewModel.storiesModel)
            .alert(item: $viewModel.error, content: { $0.alert })
            .actionSheet(item: $viewModel.actionSheet, content: { $0.sheet })
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
