//
//  WalletConnectCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WalletConnectCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WalletConnectCoordinator

    var body: some View {
        if let model = coordinator.walletConnectViewModel {
            OldWalletConnectView(viewModel: model)
                .sheet(item: $coordinator.qrScanViewCoordinator) {
                    QRScanViewCoordinatorView(coordinator: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}
