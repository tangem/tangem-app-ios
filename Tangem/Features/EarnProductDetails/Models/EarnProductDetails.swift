//
//  EarnProductDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct EarnProductDetails: Equatable {
    let benefits: [Benefit]
    let risk: Detail
    let provider: Link?
    let withdrawals: Detail
    let managementFee: Detail?
    let performanceFee: Detail
    let auditReport: Link?

    enum RiskLevel: CaseIterable {
        case low
        case medium
        case high
    }

    struct Benefit: Hashable {
        let icon: ImageType
        let title: String
        let description: String
    }

    struct Link: Equatable {
        let title: String
        let name: String
        let url: URL
    }

    struct Detail: Equatable {
        let value: String
        let info: InfoSheet
    }

    struct InfoSheet: Identifiable, Hashable {
        let title: String
        let content: Content

        var id: String { title }

        enum Content: Hashable {
            case text(String)
            case levels([Level])
        }

        struct Level: Hashable {
            let title: String
            let text: String
        }
    }
}
