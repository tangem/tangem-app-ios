//
//  SecurityManagementCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityManagementCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SecurityManagementCoordinator

    var body: some View {
        if let model = coordinator.secManagementViewModel {
            SecurityManagementView(viewModel: model)
                .navigation(item: $coordinator.cardOperationViewModel) {
                    CardOperationView(viewModel: $0)
                }
                .emptyNavigationLink()
        }
    }
}
