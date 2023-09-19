//
//  AddCustomTokenNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AddCustomTokenNetworkSelectorItemViewModel {
    let iconName: String
    let networkName: String
    let currencyCode: String
    let isSelected: Bool
    let didTapWallet: () -> Void
}
