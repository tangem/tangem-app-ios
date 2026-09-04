//
//  CollectiblesAccountStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CollectiblesAccountStatusProvider {
    func load() async throws -> CollectiblesAccountStatus
}
