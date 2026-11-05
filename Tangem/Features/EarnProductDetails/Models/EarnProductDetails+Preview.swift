//
//  EarnProductDetails+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnProductDetails {
    static let preview = EarnProductDetails.lendingOnAave(
        performanceFee: 0.15,
        auditReportURL: URL(string: "https://example.com/audit-report")
    )
}
