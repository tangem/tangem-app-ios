//
//  DeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A `package` access level due to its use in the `TangemBackendAuthenticationDebugSupport` module.
package protocol DeviceRegistrationStatusRepository: Sendable {
    func retrieve() -> Bool
    func persist(isRegistered: Bool)
}
