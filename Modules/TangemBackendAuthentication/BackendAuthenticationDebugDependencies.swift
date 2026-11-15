//
//  BackendAuthenticationDebugDependencies.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A `package` access level due to its use in the `TangemBackendAuthenticationDebugSupport` module.
package struct BackendAuthenticationDebugDependencies: Sendable {
    package let deviceKeyManager: DeviceKeyManager
    package let deviceRegistrationStatusRepository: any DeviceRegistrationStatusRepository
    package let sessionTokensRepository: any SessionTokensRepository
    private let renewSessionTokensUseCase: RenewSessionTokensUseCase

    init(
        deviceKeyManager: DeviceKeyManager,
        deviceRegistrationStatusRepository: any DeviceRegistrationStatusRepository,
        sessionTokensRepository: any SessionTokensRepository,
        renewSessionTokensUseCase: RenewSessionTokensUseCase
    ) {
        self.deviceKeyManager = deviceKeyManager
        self.deviceRegistrationStatusRepository = deviceRegistrationStatusRepository
        self.sessionTokensRepository = sessionTokensRepository
        self.renewSessionTokensUseCase = renewSessionTokensUseCase
    }

    /// A wrapper method to erase concrete error types.
    package func renewSessionTokens() async throws -> SessionTokens {
        try await renewSessionTokensUseCase()
    }
}
