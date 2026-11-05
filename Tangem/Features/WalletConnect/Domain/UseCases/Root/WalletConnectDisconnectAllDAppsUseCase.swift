//
//  WalletConnectDisconnectAllDAppsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLogger

struct WalletConnectDisconnectAllDAppsUseCase {
    private let disconnectDAppService: any WalletConnectDisconnectDAppService
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository
    private let analyticsLogger: any WalletConnectAnalyticsLogger
    private let logger: TangemLogger.Logger

    init(
        disconnectDAppService: some WalletConnectDisconnectDAppService,
        connectedDAppRepository: some WalletConnectConnectedDAppRepository,
        analyticsLogger: some WalletConnectAnalyticsLogger,
        logger: TangemLogger.Logger
    ) {
        self.disconnectDAppService = disconnectDAppService
        self.connectedDAppRepository = connectedDAppRepository
        self.analyticsLogger = analyticsLogger
        self.logger = logger
    }

    func callAsFunction() async throws(WalletConnectDAppPersistenceError) {
        let connectedDApps = try await connectedDAppRepository.getAllDApps()
        let dAppsBySessionTopic = Dictionary(grouping: connectedDApps, by: \.session.topic)

        await withTaskGroup(of: Void.self) { [disconnectDAppService, analyticsLogger, logger] group in
            for (sessionTopic, dApps) in dAppsBySessionTopic {
                let dAppData = dApps[0].dAppData

                group.addTask {
                    do {
                        try await disconnectDAppService.disconnect(with: sessionTopic)
                        analyticsLogger.logDAppDisconnected(dAppData: dAppData)
                    } catch {
                        logger.error("Failed to disconnect \(dAppData.name) dApp", error: error)
                    }
                }
            }
        }

        try await connectedDAppRepository.deleteDApps(with: Set(dAppsBySessionTopic.keys))
    }
}
