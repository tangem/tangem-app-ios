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
            }
        }
    }
}
