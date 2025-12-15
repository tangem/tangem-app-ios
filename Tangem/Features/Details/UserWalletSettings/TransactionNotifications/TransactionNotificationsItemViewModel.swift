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
    let iconImageAsset: ImageType

    // MARK: - Init

    init(
        networkName: String,
        networkSymbol: String,
        iconImageAsset: ImageType,
        isLoading: Bool = false
    ) {
        self.networkName = networkName
        self.networkSymbol = networkSymbol
        self.iconImageAsset = iconImageAsset
        self.isLoading = isLoading
    }
}
