//
//  JointAccountCreationHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Accumulates the input collected by the joint account creation flow, which spans several screens,
/// until there is enough of it to actually create the account.
/// - Note: Created by [REDACTED_AUTHOR]
final class JointAccountCreationHelper {
    var formData: FormData? {
        state.withLock { $0.formData }
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func update(name: String, icon: AccountModel.CompositeIcon) {
        state.withLock { $0.formData = FormData(name: name, icon: icon) }
    }
}

// MARK: - Auxiliary types

extension JointAccountCreationHelper {
    struct FormData {
        let name: String
        let icon: AccountModel.CompositeIcon
    }
}

private extension JointAccountCreationHelper {
    struct State {
        var formData: FormData?
    }
}
