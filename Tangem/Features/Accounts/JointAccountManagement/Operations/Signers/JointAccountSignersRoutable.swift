//
//  JointAccountSignersRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountSignersRoutable: AnyObject {
    /// Back to the operation the list belongs to.
    func returnToOperationFromSigners()
    /// Out of the operation altogether.
    func closeSigners()
}
