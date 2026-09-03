//
//  StubDeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@testable import TangemBackendAuthentication

struct StubDeviceRegistrationStatusRepository: DeviceRegistrationStatusRepository {
    var retrieveResult = false

    func retrieve() -> Bool {
        retrieveResult
    }

    func persist(isRegistered: Bool) {}
}
