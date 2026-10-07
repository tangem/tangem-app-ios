//
//  AccountDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct AccountDetailsCoordinatorView: View {
    @ObservedObject var coordinator: AccountDetailsCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AccountDetailsView(viewModel: rootViewModel)
                    .navigationTitle(rootViewModel.title)
                    .padding(.horizontal, 16)
                    .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
                    .navigationLinks(links)
            }

            sheets
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.manageTokensCoordinator) {
                ManageTokensCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.jointAccountManagementCoordinator) {
                JointAccountManagementCoordinatorView(coordinator: $0, dismissStyle: .back)
            }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.editAccountViewModel) { viewModel in
                NavigationStack {
                    AccountFormView(viewModel: viewModel)
                }
                .presentation(onDismissalAttempt: viewModel.onClose)
                .presentationCornerRadius(24)
            }
    }
}
