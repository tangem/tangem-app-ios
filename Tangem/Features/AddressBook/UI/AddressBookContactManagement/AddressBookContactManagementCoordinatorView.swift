//
//  AddressBookContactManagementCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddressBookContactManagementCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddressBookContactManagementCoordinator

    var body: some View {
        NavigationStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddressBookContactManagementView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }
        }
        .sheet(item: $coordinator.qrScanCoordinator) {
            MainQRScanCoordinatorView(coordinator: $0)
                .ignoresSafeArea()
        }
        .floatingSheetContent(for: AddressActionsViewModel.self) { viewModel in
            AddressActionsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addAddressViewModel) {
                AddressBookAddAddressView(viewModel: $0)
            }
    }
}
