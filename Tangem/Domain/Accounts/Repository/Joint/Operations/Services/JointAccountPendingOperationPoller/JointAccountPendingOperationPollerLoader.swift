//
//  JointAccountPendingOperationPollerLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountPendingOperationPollerLoader: AnyObject {
    func reloadPendingOperation(with operationId: String, in cryptoAccountId: String, knownETag: String?) async throws -> JointOperationFetchResult
}
