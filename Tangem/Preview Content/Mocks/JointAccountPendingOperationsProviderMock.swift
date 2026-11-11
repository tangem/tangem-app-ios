//
//  JointAccountPendingOperationsProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct JointAccountPendingOperationsProviderMock: JointAccountPendingOperationsProvider {
    func hasPendingOperations(chainId: Int) -> Bool {
        false
    }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        nil
    }

    func pendingOperation(from operation: JointAccountOperation) async throws -> JointAccountPendingOperation {
        throw JointAccountPendingOperationsProviderError.walletNotFound
    }

    func loadOperation(id: String) async throws -> JointAccountPendingOperation {
        throw JointOperationError.operationNotFound
    }
}
