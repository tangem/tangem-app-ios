//
//  JointAccountPendingOperationHandleProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountPendingOperationHandleProvider: AnyObject {
    func makeHandle(for pendingOperation: JointAccountPendingOperation) -> JointAccountPendingOperationHandle
}
