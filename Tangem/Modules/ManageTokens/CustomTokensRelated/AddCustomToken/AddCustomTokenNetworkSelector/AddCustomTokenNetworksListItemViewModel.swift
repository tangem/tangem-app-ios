//
//  AddCustomTokenNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class AddCustomTokenNetworksListItemViewModel: ObservableObject {
    @Published var isSelected: Bool

    let networkId: String
    let iconName: String
    let networkName: String
    let currencySymbol: String
    let didTapWallet: () -> Void

    init(
        networkId: String,
        iconName: String,
        networkName: String,
        currencySymbol: String,
        isSelected: Bool,
        didTapWallet: @escaping () -> Void
    ) {
        self.networkId = networkId
        self.iconName = iconName
        self.networkName = networkName
        self.currencySymbol = currencySymbol
        self.isSelected = isSelected
        self.didTapWallet = didTapWallet
    }
}
