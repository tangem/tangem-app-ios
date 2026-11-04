//
//  ConnectionsQRScanCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct ConnectionsQRScanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ConnectionsQRScanCoordinator

    var body: some View {
        if let viewModel = coordinator.viewModel {
            ConnectionsQRScanView(viewModel: viewModel)
        }
    }
}
