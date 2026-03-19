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
            content
            NavHolder()
                .alert(item: $coordinator.alert) { $0.alert }
        }
        .animation(SendTransitions.animation, value: coordinator.viewState)
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .scanner:
            if let qrScanCoordinator = coordinator.qrScanCoordinator {
                MainQRScanCoordinatorView(coordinator: qrScanCoordinator)
                    .transition(SendTransitions.transition)
            }
        case .send:
            if let sendCoordinator = coordinator.sendCoordinator {
                SendCoordinatorView(coordinator: sendCoordinator)
                    .transition(SendTransitions.transition)
            }
        }
    }
}
