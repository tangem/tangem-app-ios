//
//  TransferConfirmationSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TransferConfirmationSection: Identifiable, Equatable {
    let id: ID
    let header: String?
    let rows: [Row]
    let editTarget: TransferConfirmationEditTarget?

    enum ID: Hashable {
        case account
        case beneficiary
        case bank
    }

    struct Row: Identifiable, Equatable {
        let id: TangemPayFormField.ID
        let title: String
        let value: String
    }
}

// MARK: - Edit target

enum TransferConfirmationEditTarget: Hashable {
    case amount
    case personalDetails
    case bankDetails
}
