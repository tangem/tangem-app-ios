//
//  CoinViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CoinViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [CoinItemViewModel]

    init(imageURL: URL?, name: String, symbol: String, items: [CoinItemViewModel]) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
    }

    init(with model: CoinModel, items: [CoinItemViewModel]) {
        self.name = model.name
        self.symbol = model.symbol
        self.imageURL = model.imageURL
        self.items = items
    }

    func hasContractAddress(_ contractAddress: String) -> Bool {
        items.contains { item in
            guard let tokenContractAddress = item.tokenItem.contractAddress else {
                return false
            }

            return tokenContractAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
        }
    }
}

extension CoinViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CoinViewModel, rhs: CoinViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
