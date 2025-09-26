//
//  ArchivedAccountsCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemLocalization

struct ArchivedAccountsCoordinatorView: View {
    @ObservedObject var coordinator: ArchivedAccountsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                ArchivedAccountsView(viewModel: viewModel)
                    .navigationTitle(Localization.accountArchivedTitle)
            }

            sheets

            alerts
        }
    }

    private var sheets: some View {
        NavHolder()
            .confirmationDialog(
                Localization.accountDetailsArchiveDescription,
                isPresented: $coordinator.recoverAccountDialogPresented,
                titleVisibility: .hidden,
                presenting: coordinator.recoverAction
            ) { action in
                Button(Localization.accountArchivedRecoverDialogTitle) {
                    action()
                }
            }
    }

    private var alerts: some View {
        NavHolder()
            .alert(item: $coordinator.alertBinder, content: { $0.alert })
    }
}
