//
//  TokenSelectorAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TokenSelectorAccountModelItemsProvider {
    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> { get }
}
