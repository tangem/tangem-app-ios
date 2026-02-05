//
//  WelcomeSearchTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct WelcomeSearchTokensView: View {
    @ObservedObject var viewModel: WelcomeSearchTokensViewModel

    var body: some View {
        NavigationStack {
            ManageTokensListView(viewModel: viewModel.manageTokensListViewModel, isReadOnly: true)
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle(Text(Localization.commonSearchTokens))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.enteredSearchText.value, placement: .navigationBarDrawer(displayMode: .always))
                .keyboardType(.alphabet)
                .autocorrectionDisabled()
                .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
                .onAppear { viewModel.onAppear() }
                .onDisappear { viewModel.onDisappear() }
        }
    }
}
