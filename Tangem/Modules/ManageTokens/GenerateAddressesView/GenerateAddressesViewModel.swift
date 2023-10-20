//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GenerateAddressesViewModel {
    // MARK: - Properties

    let numberOfNetworks: Int
    let currentWalletNumber: Int
    let totalWalletNumber: Int
    let didTapGenerate: () -> Void
}
