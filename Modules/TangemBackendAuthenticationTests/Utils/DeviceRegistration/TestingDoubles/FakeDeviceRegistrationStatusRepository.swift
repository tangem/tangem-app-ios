//
//  FakeDeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@testable import TangemBackendAuthentication

struct FakeDeviceRegistrationStatusRepository: DeviceRegistrationStatusRepository {
    func retrieve() -> Bool {
        false
    }

    func persist(isRegistered: Bool) {}
}
