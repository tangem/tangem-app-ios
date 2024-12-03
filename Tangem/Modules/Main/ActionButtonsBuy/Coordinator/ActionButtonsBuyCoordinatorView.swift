//
//  ActionButtonsBuyCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsBuyCoordinatorView: View {
    @ObservedObject var coordinator: ActionButtonsBuyCoordinator

    var body: some View {
        if let sendCoordinator = coordinator.sendCoordinator {
            SendCoordinatorView(coordinator: sendCoordinator)
        } else if let actionButtonsBuyViewModel = coordinator.actionButtonsBuyViewModel {
            NavigationView {
                ActionButtonsBuyView(viewModel: actionButtonsBuyViewModel)
            }
        }
    }
}
