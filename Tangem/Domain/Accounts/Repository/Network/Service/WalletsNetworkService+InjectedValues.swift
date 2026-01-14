//
//  WalletsNetworkService+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension InjectedValues {
    var walletsNetworkServiceFactory: WalletsNetworkServiceFactory {
        get { Self[WalletsNetworkServiceFactoryKey.self] }
        set { Self[WalletsNetworkServiceFactoryKey.self] = newValue }
    }
}

// MARK: - Factory

struct WalletsNetworkServiceFactory {
    func makeWalletsNetworkService(userWalletId: UserWalletId) -> WalletsNetworkService {
        CommonWalletsNetworkService(userWalletId: userWalletId)
    }
}

// MARK: - Private implementation

private struct WalletsNetworkServiceFactoryKey: InjectionKey {
    static var currentValue: WalletsNetworkServiceFactory = WalletsNetworkServiceFactory()
}
