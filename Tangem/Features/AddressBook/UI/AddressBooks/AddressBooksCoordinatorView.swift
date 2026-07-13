//
//  AddressBooksCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddressBooksCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddressBooksCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddressBooksView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.contactManagementCoordinator) { contactManagementCoordinator in
                AddressBookContactManagementCoordinatorView(coordinator: contactManagementCoordinator)
                    .presentation(onDismissalAttempt: { contactManagementCoordinator.rootViewModel?.userDidRequestDismiss() })
            }
    }
}
