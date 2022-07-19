//
//  SecurityModeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityModeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SecurityModeCoordinator

    var body: some View {
        if let model = coordinator.secManagementViewModel {
            SecurityModeView(viewModel: model)
                .navigation(item: $coordinator.cardOperationViewModel) {
                    CardOperationView(viewModel: $0)
                }
                .emptyNavigationLink()
        }
    }
}
