//
//  ConnectionsCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ConnectionsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ConnectionsCoordinator

    var body: some View {
        if let viewModel = coordinator.viewModel {
            ConnectionsView(viewModel: viewModel)
                .fullScreenCover(item: $coordinator.qrScanCoordinator) {
                    ConnectionsQRScanCoordinatorView(coordinator: $0)
                        .softTopScrollEdgeEffect()
                }
        }
    }
}
