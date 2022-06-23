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
            WalletConnectView(viewModel: model)
                .sheet(item: $coordinator.qrScanViewModel) {
                    QRScanView(viewModel: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}
