//
//  GachaAccountSummaryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol GachaAccountSummaryProvider {
    func load() async throws -> GachaAccountSummary
}
