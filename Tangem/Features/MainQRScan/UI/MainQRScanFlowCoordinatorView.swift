//
//  MainQRScanFlowCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainQRScanFlowCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainQRScanFlowCoordinator

    var body: some View {
        ZStack {
            if let qrScanCoordinator = coordinator.qrScanCoordinator {
                MainQRScanCoordinatorView(coordinator: qrScanCoordinator)
            }

            NavHolder()
                .alert(item: $coordinator.alert) { $0.alert }
        }
    }
}
