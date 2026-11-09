//
//  JointAccountPendingOperationHandleProviderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class JointAccountPendingOperationHandleProviderStub: JointAccountPendingOperationHandleProvider {
    func makeHandle(for pendingOperation: JointAccountPendingOperation) -> JointAccountPendingOperationHandle {
        JointAccountPendingOperationHandle(
            id: pendingOperation.id,
            wallet: pendingOperation.wallet,
            pendingOperationPublisher: Empty().eraseToAnyPublisher()
        )
    }
}
