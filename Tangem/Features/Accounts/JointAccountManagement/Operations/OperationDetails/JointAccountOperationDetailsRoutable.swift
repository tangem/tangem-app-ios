//
//  JointAccountOperationDetailsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Note: Closing is all the sheet asks of the outside: answering an operation and naming who has answered it stay
///   within the sheet, which swaps its own content the way the fee selector does.
protocol JointAccountOperationDetailsRoutable: AnyObject {
    func closeOperationDetails()
}
