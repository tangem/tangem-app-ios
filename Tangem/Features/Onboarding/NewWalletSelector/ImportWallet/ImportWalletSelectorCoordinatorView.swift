//
//  ImportWalletSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ImportWalletSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ImportWalletSelectorCoordinator

    var body: some View {
        ZStack {
            if let importViewModel = coordinator.importViewModel {
                ImportWalletSelectorView(viewModel: importViewModel)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .emptyNavigationLink()
    }
}
