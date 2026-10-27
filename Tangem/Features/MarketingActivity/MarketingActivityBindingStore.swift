//
//  MarketingActivityBindingStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketingActivityBindingStore {
    @discardableResult
    func add(uid: String) async -> MarketingActivityBinding
    func pending() async -> [MarketingActivityBinding]
    func remove(id: UUID) async
}
