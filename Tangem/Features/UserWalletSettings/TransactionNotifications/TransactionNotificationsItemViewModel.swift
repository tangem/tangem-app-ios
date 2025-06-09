//
//  TransactionNotificationsItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

class TransactionNotificationsItemViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()

    let isLoading: Bool
    let networkName: String
    let networkSymbol: String

    var iconImageAsset: ImageType {
        imageAsset
    }

    // MARK: - Private Properties

    private let imageAsset: ImageType

    // MARK: - Init

    init(
        blockchainNetwork: BlockchainNetwork,
        isLoading: Bool = false,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider()
    ) {
        imageAsset = blockchainIconProvider.provide(by: blockchainNetwork.blockchain, filled: true)
        networkName = blockchainNetwork.blockchain.displayName
        networkSymbol = blockchainNetwork.blockchain.currencySymbol
        self.isLoading = isLoading
    }
}
