//
//  WalletConnectQRScanCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectQRScanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WalletConnectQRScanCoordinator

    var body: some View {
        if let viewModel = coordinator.viewModel {
            WalletConnectQRScanView(viewModel: viewModel)
        }
    }
}
