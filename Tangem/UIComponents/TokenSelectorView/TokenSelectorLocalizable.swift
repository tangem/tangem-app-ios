//
//  TokenSelectorLocalizable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol TokenSelectorLocalizable {
    var availableTokensListTitle: String { get }
    var unavailableTokensListTitle: String { get }
    var emptySearchMessage: String { get }
    var emptyTokensMessage: String? { get }
}
