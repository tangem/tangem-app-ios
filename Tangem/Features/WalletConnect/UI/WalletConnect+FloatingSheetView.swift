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

extension View {
    private var kingfisherImageCache: ImageCache {
        InjectedValues[\.walletConnectKingfisherImageCache]
    }

    func registerWalletConnectFloatingSheets() -> some View {
        floatingSheetContent(for: WalletConnectDAppConnectionViewModel.self) {
            WalletConnectDAppConnectionView(viewModel: $0, kingfisherImageCache: kingfisherImageCache)
        }
        .floatingSheetContent(for: WalletConnectConnectedDAppDetailsViewModel.self) { viewModel in
            WalletConnectConnectedDAppDetailsView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }
        .floatingSheetContent(for: WCTransactionViewModel.self) {
            WCTransactionView(viewModel: $0)
        }
    }
}

extension WalletConnectConnectedDAppDetailsViewModel: FloatingSheetContentViewModel {}
extension WalletConnectDAppConnectionViewModel: FloatingSheetContentViewModel {}
