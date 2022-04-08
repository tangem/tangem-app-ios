//
//  CurrencyViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CurrencyViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let items: [CurrencyItemViewModel]
    
    init(imageURL: URL?, name: String, symbol: String, items: [CurrencyItemViewModel]) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.items = items
    }
    
    init?(with currency: CurrencyModel, items: [CurrencyItemViewModel]) {
        self.name = currency.name
        self.symbol = currency.symbol
        self.imageURL = currency.imageURL
        self.items = items
    }
    
    func hasContractAddress(_ contractAddress: String) -> Bool {
        items.contains { item in
            guard let tokenContractAddress = item.tokenItem.contractAddress else {
                return false
            }
            
            return tokenContractAddress == contractAddress
        }
    }
}

extension CurrencyViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CurrencyViewModel, rhs: CurrencyViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
