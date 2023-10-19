//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

class GenerateAddressesViewModel: ObservableObject {
    // MARK: - Properties

    @Published var numberOfNetworks: Int = 0
    @Published var currentWalletNumber: Int = 0
    @Published var totalWalletNumber: Int = 0

    let didTapGenerate: () -> Void

    // MARK: - Init

    init(numberOfNetworks: Int, currentWalletNumber: Int, totalWalletNumber: Int, didTapGenerate: @escaping () -> Void) {
        self.numberOfNetworks = numberOfNetworks
        self.currentWalletNumber = currentWalletNumber
        self.totalWalletNumber = totalWalletNumber
        self.didTapGenerate = didTapGenerate
    }
}
