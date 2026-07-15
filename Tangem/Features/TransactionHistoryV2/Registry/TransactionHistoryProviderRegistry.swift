//
//  TransactionHistoryProviderRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryProviderRegistry: Sendable {
    func provider(for key: TransactionHistoryProviderKey) async -> any TransactionHistoryProviding
}
