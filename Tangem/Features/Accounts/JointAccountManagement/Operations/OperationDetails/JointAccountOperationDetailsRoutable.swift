//
//  JointAccountOperationDetailsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountOperationDetailsRoutable: AnyObject {
    /// Who has answered the operation, which is a screen of its own.
    func openSigners()
    /// Hands the operation to the signing flow; the sheet itself never signs.
    func signOperation()
    func closeOperationDetails()
}
