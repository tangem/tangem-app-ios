//
//  TangemPayOfframpWizardStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TangemPayOfframpWizardStep {
    case amount
    case transferType
    case accountType
    case personalDetails
    case bankDetails

    func subtitle(for recipient: TangemPayOfframpRecipient) -> String? {
        let order = Self.order(for: recipient)

        guard let index = order.firstIndex(of: self) else {
            return nil
        }

        // [REDACTED_TODO_COMMENT]
        return "\(index + 1) of \(order.count)"
    }
}

// MARK: - Flows

private extension TangemPayOfframpWizardStep {
    static func order(for recipient: TangemPayOfframpRecipient) -> [Self] {
        switch recipient {
        case .saved:
            []
        case .newIndividual:
            [.amount, .transferType, .accountType, .personalDetails, .bankDetails]
        case .newBusiness:
            [.amount, .accountType, .personalDetails, .bankDetails]
        }
    }
}
