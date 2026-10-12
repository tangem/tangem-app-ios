//
//  JointAccountMemberNameHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// What the member name step needs from the flow showing it: how to label itself, and what to do with the name.
protocol JointAccountMemberNameHelper {
    var submitButtonTitle: String { get }
    var initialName: String { get }
    var tangemIconProvider: TangemIconProvider { get }
    /// Whether leaving the step would throw away what earlier steps of the flow gathered.
    var hasUnsavedChanges: Bool { get }

    /// Owns the whole operation, card session included — the button keeps spinning until this returns.
    func submit(name: String) async throws(AccountEditError)
}
