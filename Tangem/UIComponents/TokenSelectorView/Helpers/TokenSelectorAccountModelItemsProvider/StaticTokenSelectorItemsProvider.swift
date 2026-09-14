//
//  StaticTokenSelectorItemsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct StaticTokenSelectorItemsProvider: TokenSelectorAccountModelItemsProvider {
    let items: [TokenSelectorItem]

    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        Just(items).eraseToAnyPublisher()
    }
}
