//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class GenerateAddressesViewModel: Identifiable {
    // MARK: - Properties

    let numberOfNetworks: Int
    let currentWalletNumber: Int
    let totalWalletNumber: Int
    let didTapGenerate: () -> Void

    init(numberOfNetworks: Int, currentWalletNumber: Int, totalWalletNumber: Int, didTapGenerate: @escaping () -> Void) {
        self.numberOfNetworks = numberOfNetworks
        self.currentWalletNumber = currentWalletNumber
        self.totalWalletNumber = totalWalletNumber
        self.didTapGenerate = didTapGenerate
    }
}
