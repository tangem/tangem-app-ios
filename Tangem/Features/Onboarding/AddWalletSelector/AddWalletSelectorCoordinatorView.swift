//
//  AddWalletSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddWalletSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddWalletSelectorCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                AddWalletSelectorView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.hardwareCreateWalletCoordinator) {
                HardwareCreateWalletCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.mobileCreateWalletCoordinator) {
                MobileCreateWalletCoordinatorView(coordinator: $0)
            }
    }
}
