//
//  TokenMarketsNetworkSelectorCoordinatorView.swift
//  Tangem
//
//  Created by skibinalexander on 21.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenNetworkSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MarketsTokenNetworkSelectorCoordinator

    var body: some View {
        if let viewModel = coordinator.rootViewModel {
            MarketsTokensNetworkSelectorView(
                viewModel: viewModel,
                walletSelectorViewModel: $coordinator.walletSelectorViewModel
            )
        }
    }
}
