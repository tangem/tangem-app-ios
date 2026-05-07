//
//  WalletConnectPayCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectPayCoordinatorView: View {
    @ObservedObject var coordinator: WalletConnectPayCoordinator

    var body: some View {
        if let viewModel = coordinator.viewModel {
            WalletConnectPayView(viewModel: viewModel)
        }
    }
}
