//
//  WalletConnect+InjectedValues.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import typealias Foundation.TimeInterval
import class Kingfisher.ImageCache

private final class WalletConnectEnvironment {
    @Injected(\.walletConnectSessionsStorage) private var legacySessionsStorage: any WalletConnectSessionsStorage
    @Injected(\.persistentStorage) private var persistentStorage: any PersistentStorageProtocol
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    lazy var kingfisherCache: ImageCache = {
        let inMemoryCacheCountLimit = 50
        let fifteenMinutesInSeconds: TimeInterval = 900

        let cache = ImageCache(name: "com.tangem.walletconnect.icons")
        cache.memoryStorage.config.countLimit = inMemoryCacheCountLimit
        cache.memoryStorage.config.expiration = .seconds(fifteenMinutesInSeconds)

        return cache
    }()

    lazy var connectedDAppRepository = PersistentStorageWalletConnectConnectedDAppRepository(persistentStorage: persistentStorage)
    lazy var wcService = CommonWCService()
    lazy var dAppVerificationService = BlockaidWalletConnectDAppVerificationService(apiService: BlockaidFactory().makeBlockaidAPIService())

    lazy var dAppSessionsExtender = CommonWalletConnectDAppSessionsExtender(
        connectedDAppRepository: connectedDAppRepository,
        savedSessionMigrationService: WalletConnectSavedSessionMigrationService(
            sessionsStorage: legacySessionsStorage,
            userWalletRepository: userWalletRepository,
            dAppVerificationService: dAppVerificationService,
            appSettings: AppSettings.shared
        ),
        walletConnectService: wcService
    )
}

private struct WalletConnectEnvironmentInjectionKey: InjectionKey {
    static var currentValue = WalletConnectEnvironment()
}

extension InjectedValues {
    private var walletConnectEnvironment: WalletConnectEnvironment {
        get { Self[WalletConnectEnvironmentInjectionKey.self] }
        set { Self[WalletConnectEnvironmentInjectionKey.self] = newValue }
    }

    var walletConnectKingfisherImageCache: ImageCache {
        walletConnectEnvironment.kingfisherCache
    }

    var connectedDAppRepository: any WalletConnectConnectedDAppRepository {
        walletConnectEnvironment.connectedDAppRepository
    }

    var wcService: any WCService {
        walletConnectEnvironment.wcService
    }

    var dAppVerificationService: any WalletConnectDAppVerificationService {
        walletConnectEnvironment.dAppVerificationService
    }

    var dAppSessionsExtender: any WalletConnectDAppSessionsExtender {
        walletConnectEnvironment.dAppSessionsExtender
    }
}
