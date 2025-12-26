//
//  AccountsAwareNetworkSelectorItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

final class AccountsAwareNetworkSelectorItemViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()

    let tokenItem: TokenItem
    let networkName: String
    let contractName: String?
    let isReadonly: Bool
    let onTap: (() -> Void)?

    var networkNameForegroundColor: Color {
        isReadonly ? Colors.Text.disabled : Colors.Text.primary1
    }

    var contractNameForegroundColor: Color {
        isReadonly ? Colors.Text.disabled : Colors.Text.tertiary
    }

    var iconImageAsset: ImageType {
        isReadonly ? imageAsset : imageAssetSelected
    }

    private let imageAsset: ImageType
    private let imageAssetSelected: ImageType

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        isReadonly: Bool,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider(),
        onTap: (() -> Void)? = nil
    ) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        self.onTap = onTap
        imageAsset = blockchainIconProvider.provide(by: tokenItem.blockchain, filled: false)
        imageAssetSelected = blockchainIconProvider.provide(by: tokenItem.blockchain, filled: true)
        networkName = tokenItem.blockchain.displayName
        contractName = tokenItem.contractName
    }

    func handleTap() {
        guard !isReadonly else { return }
        onTap?()
    }
}
