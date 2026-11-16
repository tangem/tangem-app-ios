//
//  BackendAuthenticationDebugModuleFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemBackendAuthenticationDebugSupport
import enum TangemFoundation.AppEnvironment

enum BackendAuthenticationDebugModuleFactory {
    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    @MainActor
    static func makeViewModel() -> BackendAuthenticationDebugViewModel {
        let apiType = AppEnvironment.current.backendAuthenticationAPIType

        return BackendAuthenticationDebugAssembly.makeViewModel(
            environmentName: apiType.rawValue,
            baseURL: apiType.baseURL,
            userWalletInfos: userWalletRepository.models.map { userWalletModel in
                BackendAuthenticationDebugViewModel.UserWalletInfo(id: userWalletModel.userWalletId, name: userWalletModel.name)
            },
            logger: BackendAuthLogger
        )
    }
}
