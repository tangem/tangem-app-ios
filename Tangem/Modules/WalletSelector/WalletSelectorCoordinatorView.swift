//
//  WalletSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WalletSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WalletSelectorCoordinator

    var body: some View {
        NavigationView {
            if let viewModel = coordinator.walletSelectorViewModel {
                WalletSelectorView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .emptyNavigationLink()
    }
}
