//
//  CollectiblesAccountSummaryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesAccountSummaryProvider {
    func load() async throws -> CollectiblesAccountSummary
}
