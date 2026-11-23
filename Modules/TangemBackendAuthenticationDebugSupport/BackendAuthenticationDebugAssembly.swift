//
//  BackendAuthenticationDebugAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
import TangemBackendAuthentication
public import struct TangemLogger.Logger

public enum BackendAuthenticationDebugAssembly {
    @MainActor
    public static func makeViewModel(
        environmentName: String,
        baseURL: URL,
        userWalletInfos: [BackendAuthenticationDebugViewModel.UserWalletInfo],
        logger: Logger
    ) -> BackendAuthenticationDebugViewModel {
        BackendAuthenticationDebugViewModel(
            environmentName: environmentName,
            baseURL: baseURL,
            userWalletInfos: userWalletInfos,
            debugService: BackendAuthenticationDebugService(
                dependencies: BackendAuthenticationAssembly.debugDependencies,
                dateProvider: Date.now
            ),
            registerDevice: BackendAuthenticationAssembly.registerDevice,
            unregisterUserWallet: BackendAuthenticationAssembly.unregisterUserWallet,
            retrieveUserWalletRegistrationStatus: BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus,
            logger: logger
        )
    }

    public static func resetAll() async {
        await BackendAuthenticationDebugService(
            dependencies: BackendAuthenticationAssembly.debugDependencies,
            dateProvider: Date.now
        )
        .resetAll()
    }
}
