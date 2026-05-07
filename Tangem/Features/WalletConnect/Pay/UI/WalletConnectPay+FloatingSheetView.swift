//
//  WalletConnectPay+FloatingSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension FloatingSheetRegistry {
    func registerWalletConnectPayFloatingSheets() {
        guard FeatureProvider.isAvailable(.walletConnectPay) else {
            return
        }

        register(WalletConnectPayViewModel.self) { viewModel in
            WalletConnectPayView(viewModel: viewModel)
        }
    }
}
