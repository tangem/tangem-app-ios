//
//  ActionButtonsSellCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsSellCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsSellCoordinator

    var body: some View {
        if let actionButtonsSellViewModel = coordinator.actionButtonsSellViewModel {
            NavigationView {
                ActionButtonsSellView(viewModel: actionButtonsSellViewModel)
            }
        }
    }
}
