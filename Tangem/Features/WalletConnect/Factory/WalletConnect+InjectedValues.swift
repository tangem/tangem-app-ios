//
//  WalletConnect+InjectedValues.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class Kingfisher.ImageCache
import ReownWalletKit
import TangemNetworkUtils

private final class WalletConnectEnvironment {
    @Injected(\.walletConnectSessionsStorage) private var legacySessionsStorage: any WalletConnectSessionsStorage
    @Injected(\.persistentStorage) private var persistentStorage: any PersistentStorageProtocol
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private lazy var walletKitClient = WalletKitClientFactory.make()
    private lazy var messageComposer = WalletConnectV2MessageComposer()
    private lazy var alertUIDelegate = WalletConnectAlertUIDelegate()

    private lazy var handlersFactory = WalletConnectHandlersFactory(
        messageComposer: messageComposer,
        uiDelegate: alertUIDelegate,
        ethTransactionBuilder: CommonWalletConnectEthTransactionBuilder()
    )

    private lazy var handlersService = CommonWCHandlersService(wcHandlersFactory: handlersFactory)

    lazy var dAppSessionsExtender = WalletConnectDAppSessionsExtender(
        connectedDAppRepository: connectedDAppRepository,
        savedSessionMigrationService: WalletConnectSavedSessionMigrationService(
            sessionsStorage: legacySessionsStorage,
            userWalletRepository: userWalletRepository,
            dAppVerificationService: dAppVerificationService,
            dAppIconURLResolver: dAppIconURLResolver,
            appSettings: AppSettings.shared
        ),
        dAppSessionExtensionService: ReownWalletConnectDAppSessionExtensionService(walletKitClient: walletKitClient),
        logger: WCLogger
    )

    lazy var wcService: CommonWCService = {
        let v2Service = WCServiceV2(walletKitClient: walletKitClient, wcHandlersService: handlersService)
        return CommonWCService(v2Service: v2Service, dAppSessionsExtender: dAppSessionsExtender)
    }()

    lazy var dAppVerificationService = BlockaidWalletConnectDAppVerificationService(
        apiService: BlockaidFactory().makeBlockaidAPIService(),
        logger: WCLogger
    )

    lazy var dAppIconURLResolver = WalletConnectDAppIconURLResolver(
        remoteURLResourceResolver: RemoteURLResourceResolver(
            session: URLSession(configuration: .walletConnectIconsContentTypeResolveConfiguration)
        ),
        kingfisherCache: kingfisherCache
    )
    lazy var connectedDAppRepository = PersistentStorageWalletConnectConnectedDAppRepository(persistentStorage: persistentStorage)

    lazy var kingfisherCache: ImageCache = {
        let inMemoryCacheCountLimit = 50
        let fifteenMinutesInSeconds: TimeInterval = 900

        let cache = ImageCache(name: "com.tangem.walletconnect.icons")
        cache.memoryStorage.config.countLimit = inMemoryCacheCountLimit
        cache.memoryStorage.config.expiration = .seconds(fifteenMinutesInSeconds)

        return cache
    }()

    // MARK: - Legacy

    private lazy var oldHandlersService = OldWalletConnectV2HandlersService(
        uiDelegate: alertUIDelegate,
        handlersCreator: handlersFactory
    )

    lazy var oldWalletConnectService: OldCommonWalletConnectService = {
        let oldV2Service = OldWalletConnectV2Service(
            walletKitClient: walletKitClient,
            uiDelegate: alertUIDelegate,
            messageComposer: messageComposer,
            wcHandlersService: oldHandlersService
        )

        return OldCommonWalletConnectService(v2Service: oldV2Service)
    }()
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

    var dAppIconURLResolver: WalletConnectDAppIconURLResolver {
        walletConnectEnvironment.dAppIconURLResolver
    }

    var dAppSessionsExtender: WalletConnectDAppSessionsExtender {
        walletConnectEnvironment.dAppSessionsExtender
    }
}

// MARK: - Legacy

extension InjectedValues {
    var walletConnectService: any OldWalletConnectService {
        walletConnectEnvironment.oldWalletConnectService
    }
}
