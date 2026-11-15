//
//  BackendAuthenticationDebugModuleFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemBackendAuthenticationDebugSupport

enum BackendAuthenticationDebugModuleFactory {
    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    @MainActor
    static func makeViewModel() -> BackendAuthenticationDebugViewModel {
        let apiType = FeatureStorage.instance.tangemAPIType

        return BackendAuthenticationDebugAssembly.makeViewModel(
            environmentName: apiType.rawValue,
            baseURL: apiType.backendAuthenticationBaseUrl,
            userWalletInfos: userWalletRepository.models.map { userWalletModel in
                BackendAuthenticationDebugViewModel.UserWalletInfo(id: userWalletModel.userWalletId, name: userWalletModel.name)
            },
            logger: BackendAuthLogger
        )
    }
}
