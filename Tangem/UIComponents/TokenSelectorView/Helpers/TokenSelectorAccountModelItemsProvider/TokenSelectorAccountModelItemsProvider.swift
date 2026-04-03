//
//  TokenSelectorAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TokenSelectorAccountModelItemsProvider {
    var items: [TokenSelectorItem] { get }
    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> { get }
}
