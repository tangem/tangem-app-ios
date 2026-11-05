//
//  FakeAppAttestationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
@testable import TangemBackendAuthentication

final class FakeAppAttestationStatusRepository: AppAttestationStatusRepository {
    private let isAppAttested = OSAllocatedUnfairLock(initialState: false)

    func retrieve() -> Bool {
        isAppAttested.withLock { $0 }
    }

    func persist(isAppAttested: Bool) {
        self.isAppAttested.withLock { $0 = isAppAttested }
    }
}
