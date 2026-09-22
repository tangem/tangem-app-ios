//
//  JointAccountActivationConfirmationRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountActivationConfirmationRoutable: AnyObject {
    /// - Parameter activate: Handed back by the sheet, which is what carries it for as long as it is up: activating
    /// belongs to the screen that opened the sheet rather than to the flow.
    func confirmActivation(_ activate: @escaping () -> Void)
    func cancelActivation()
}
