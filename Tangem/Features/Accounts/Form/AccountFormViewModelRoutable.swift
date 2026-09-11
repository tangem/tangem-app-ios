//
//  AccountFormViewModelRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AccountFormViewModelRoutable: AnyObject {
    func closeAccountForm(outcome: AccountFormOutcome)
}

// MARK: - Auxiliary types

enum AccountFormOutcome {
    /// The form applied what was entered, the payload tells what it amounted to for the flow it belongs to.
    case completed(AccountFormOperationResult)

    /// The form was left without applying anything.
    case cancelled
}
