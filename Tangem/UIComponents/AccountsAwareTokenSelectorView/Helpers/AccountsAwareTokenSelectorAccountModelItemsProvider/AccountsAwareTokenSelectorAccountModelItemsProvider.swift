//
//  AccountsAwareTokenSelectorAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] { get }
    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> { get }
}
