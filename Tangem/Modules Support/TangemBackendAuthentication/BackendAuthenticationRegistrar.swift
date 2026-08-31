//
//  BackendAuthenticationRegistrar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemBackendAuthentication
import enum TangemFoundation.AppEnvironment
import class TangemNetworkUtils.TangemProvider

enum BackendAuthenticationRegistrar {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func registerDeviceIfNeeded(pendingKeychainCleanTask: Task<Void, Never>?) {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        BackendAuthenticationAssembly.configure(
            BackendAuthenticationAssembly.Configuration(
                baseURL: AppEnvironment.current.backendAuthenticationBaseUrl,
                appPrivateKey: keysManager.authServiceKey,
                provider: TangemProvider<BackendAuthenticationTarget>(configuration: .ephemeralConfiguration)
            )
        )

        Task {
            await pendingKeychainCleanTask?.value

            let registerDevice = BackendAuthenticationAssembly.registerDeviceUseCase

            do {
                _ = try await registerDevice()
                AppLogger.info("Device registration succeeded")
            } catch {
                AppLogger.error("Device registration failed", error: error)
            }
        }
    }
}
