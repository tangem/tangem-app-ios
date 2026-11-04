//
//  ConnectionsModuleFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIApplication
import enum TangemMCP.MCPAssembly

@MainActor
enum ConnectionsModuleFactory {
    @Injected(\.wcService) private static var walletConnectService: any WCService
    @Injected(\.dAppSessionsExtender) private static var dAppsSessionExtender: WalletConnectDAppSessionsExtender
    @Injected(\.connectedDAppRepository) private static var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.userWalletRepository) private static var userWalletRepository: any UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private static var cryptoAccountsGlobalStateProvider: any CryptoAccountsGlobalStateProvider

    private static let openSystemSettingsAction = UIApplication.openSystemSettings
    private static let cameraAccessProvider = AVWalletConnectCameraAccessProvider()

    private static let disconnectDAppService = ReownWalletConnectDisconnectDAppService(walletConnectService: Self.walletConnectService)

    static func makeViewModel(
        coordinator: some ConnectionsRoutable,
        prefetchedConnectedDApps: [WalletConnectConnectedDApp]?
    ) -> ConnectionsViewModel {
        ConnectionsViewModel(
            interactor: makeInteractor(),
            userWalletRepository: userWalletRepository,
            cryptoAccountsGlobalStateProvider: cryptoAccountsGlobalStateProvider,
            logger: ConnectionsLogger,
            coordinator: coordinator,
            prefetchedConnectedDApps: prefetchedConnectedDApps
        )
    }

    private static func makeInteractor() -> ConnectionsInteractor {
        let checkCameraAccessUseCase = ConnectionsCheckCameraAccessUseCase(
            cameraAccessProvider: cameraAccessProvider,
            openSystemSettingsAction: openSystemSettingsAction
        )

        let disconnectAllDAppsUseCase = WalletConnectDisconnectAllDAppsUseCase(
            disconnectDAppService: disconnectDAppService,
            connectedDAppRepository: connectedDAppRepository,
            // [REDACTED_TODO_COMMENT]
            analyticsLogger: CommonWalletConnectAnalyticsLogger(),
            logger: WCLogger
        )

        return ConnectionsInteractor(
            checkCameraAccess: checkCameraAccessUseCase,
            fetchMCPSessions: MCPAssembly.UseCases.fetchSessions,
            revokeDeviceMCPSessions: MCPAssembly.UseCases.revokeDeviceSessions,
            streamConnectedDApps: WalletConnectStreamConnectedDAppsUseCase(repository: connectedDAppRepository),
            extendConnectedDApps: WalletConnectExtendConnectedDAppsUseCase(sessionsExtender: dAppsSessionExtender),
            disconnectAllDApps: disconnectAllDAppsUseCase
        )
    }
}
