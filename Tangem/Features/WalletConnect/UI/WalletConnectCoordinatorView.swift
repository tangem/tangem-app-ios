//
//  WalletConnectCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemUI

struct WalletConnectCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WalletConnectCoordinator
    @Injected(\.walletConnectKingfisherImageCache) private var kingfisherImageCache: ImageCache

    var body: some View {
        if let viewModel = coordinator.viewModel {
            WalletConnectView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
                .fullScreenCover(item: $coordinator.qrScanCoordinator) {
                    WalletConnectQRScanCoordinatorView(coordinator: $0)
                        .softTopScrollEdgeEffect()
                }
        }
    }
}
