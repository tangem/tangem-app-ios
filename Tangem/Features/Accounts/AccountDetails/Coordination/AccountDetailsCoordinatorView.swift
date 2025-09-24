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
                    .navigationTitle(Localization.accountDetailsTitle)
                    .padding(.horizontal, 16)
                    .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
            }

            sheets
        }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.editAccountViewModel) { viewModel in
                NavigationView {
                    AccountFormView(viewModel: viewModel)
                }
                .presentation(onDismissalAttempt: viewModel.onClose)
                .presentationCornerRadiusBackport(24)
            }
            .confirmationDialog(
                Localization.accountDetailsArchiveDescription,
                isPresented: $coordinator.archiveAccountDialogPresented,
                titleVisibility: .visible,
                presenting: coordinator.archiveAction
            ) { action in
                Button(Localization.accountDetailsArchive, role: .destructive) {
                    do {
                        try action()

                        coordinator.dismiss()

                        Toast(view: SuccessToast(text: Localization.accountArchiveSuccessMessage))
                            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
                    } catch {
                        Toast(view: WarningToast(text: Localization.genericError))
                            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
                    }
                }
            }
    }
}
