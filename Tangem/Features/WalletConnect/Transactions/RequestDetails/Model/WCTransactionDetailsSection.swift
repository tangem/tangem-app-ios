//
//  WCTransactionDetailsSection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCTransactionDetailsSection: Identifiable, Equatable {
    let id = UUID()
    let sectionTitle: String?
    let items: [WCTransactionDetailsItem]

    struct WCTransactionDetailsItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let value: String
    }
}
