//
//  JointAccountSupportedNetworksViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAssets
import TangemUI

final class JointAccountSupportedNetworksViewModel: Identifiable {
    let networks: [NetworkViewData]

    private weak var coordinator: JointAccountSupportedNetworksRoutable?

    init(
        blockchains: [Blockchain] = JointAccountSupportedBlockchains.all,
        imageProvider: NetworkImageProvider = NetworkImageProvider(),
        coordinator: JointAccountSupportedNetworksRoutable?
    ) {
        networks = blockchains.map { blockchain in
            NetworkViewData(
                id: blockchain.networkId,
                icon: imageProvider.provide(by: blockchain, filled: true),
                name: blockchain.displayName,
                symbol: blockchain.currencySymbol
            )
        }

        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closeSupportedNetworks()
    }
}

// MARK: - Auxiliary types

extension JointAccountSupportedNetworksViewModel {
    struct NetworkViewData: Identifiable {
        let id: String
        let icon: ImageType
        let name: String
        let symbol: String
    }
}
