//
//  WalletConnect+FloatingSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemUI

extension FloatingSheetRegistry {
    func registerWalletConnectFloatingSheets() {
        let kingfisherImageCache: ImageCache = InjectedValues[\.walletConnectKingfisherImageCache]

        register(WalletConnectDAppConnectionViewModel.self) { viewModel in
            WalletConnectDAppConnectionView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }

        register(WalletConnectConnectedDAppDetailsViewModel.self) { viewModel in
            WalletConnectConnectedDAppDetailsView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }

        register(WCTransactionViewModel.self) { viewModel in
            WCTransactionView(viewModel: viewModel)
        }
    }
}

extension WalletConnectConnectedDAppDetailsViewModel: FloatingSheetContentViewModel {}
extension WalletConnectDAppConnectionViewModel: FloatingSheetContentViewModel {}
