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
        if let viewModel = coordinator.rootViewModel {
            ArchivedAccountsView(viewModel: viewModel)
                .navigationTitle(Localization.accountArchivedTitle)
        }
    }
}
