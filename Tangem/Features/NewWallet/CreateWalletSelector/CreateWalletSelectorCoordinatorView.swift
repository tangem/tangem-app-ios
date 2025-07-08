//
//  CreateWalletSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CreateWalletSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CreateWalletSelectorCoordinator

    var body: some View {
        ZStack {
            if let createViewModel = coordinator.createViewModel {
                CreateWalletSelectorView(viewModel: createViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
        .alert(item: $coordinator.error, content: { $0.alert })
        .actionSheet(item: $coordinator.actionSheet, content: { $0.sheet })
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .emptyNavigationLink()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
