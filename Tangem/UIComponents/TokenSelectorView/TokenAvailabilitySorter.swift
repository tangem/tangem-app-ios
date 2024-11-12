//
//  TokenAvailabilitySorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol TokenAvailabilitySorter {
    func sortModels(walletModels: [WalletModel]) -> (availableModels: [WalletModel], unavailableModels: [WalletModel])
}
