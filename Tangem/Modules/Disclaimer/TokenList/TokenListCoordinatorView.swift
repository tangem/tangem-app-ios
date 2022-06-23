//
//  TokenListCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

import SwiftUI

struct TokenListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenListCoordinator

    var body: some View {
        NavigationView {
            if let model = coordinator.tokenListViewModel {
                TokenListView(viewModel: model)
                    .navigationLinks(links)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addCustomTokenViewModel) {
                AddCustomTokenView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
