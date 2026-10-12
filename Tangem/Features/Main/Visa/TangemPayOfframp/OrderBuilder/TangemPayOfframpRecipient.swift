//
//  TangemPayOfframpRecipient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayOfframpRecipient: Equatable {
    case saved(bankAccountId: String)
    case newIndividual
    case newBusiness
}

// MARK: - Traits

extension TangemPayOfframpRecipient {
    var isSaved: Bool {
        if case .saved = self {
            return true
        }

        return false
    }
}
