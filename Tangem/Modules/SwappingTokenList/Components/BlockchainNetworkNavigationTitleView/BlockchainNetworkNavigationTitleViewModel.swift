//
//  BlockchainNetworkNavigationTitleViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BlockchainNetworkNavigationTitleViewModel: Hashable {
    let title: String
    let iconURL: URL
    let network: String

    var networkName: String {
        Localization.walletCurrencySubtitle(network).capitalized
    }
}
