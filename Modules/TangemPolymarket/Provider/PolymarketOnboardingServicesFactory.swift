//
//  PolymarketOnboardingServicesFactory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct PolymarketOnboardingServicesFactory {
    private let networkConfiguration: TangemProviderConfiguration
    private let environment: () -> PolymarketBFFEnvironment
    private let serverClock: PolymarketServerClock

    private var backendClockPlugins: [PolymarketServerClockPlugin] {
        [PolymarketServerClockPlugin(serverClock: serverClock)]
    }

    public init(
        networkConfiguration: TangemProviderConfiguration,
        environment: @escaping () -> PolymarketBFFEnvironment,
        serverClock: PolymarketServerClock
    ) {
        self.networkConfiguration = networkConfiguration
        self.environment = environment
        self.serverClock = serverClock
    }

    public func makeWalletService(walletId: String) -> PolymarketDepositWalletService {
        let provider = TangemProvider<PolymarketDepositWalletTarget>(
            configuration: networkConfiguration,
            additionalPlugins: backendClockPlugins
        )

        return CommonPolymarketDepositWalletService(provider: provider, environment: environment, walletId: walletId)
    }

    public func makeGeoblockService() -> PolymarketGeoblockService {
        let provider = TangemProvider<PolymarketGeoblockTarget>(configuration: networkConfiguration)

        return CommonPolymarketGeoblockService(provider: provider, baseURL: PolymarketHost.polymarket)
    }

    public func makeRelayerService() -> PolymarketRelayerService {
        let provider = TangemProvider<PolymarketRelayerTarget>(configuration: networkConfiguration)

        return CommonPolymarketRelayerService(provider: provider, baseURL: PolymarketHost.relayer)
    }

    public func makeCLOBService() -> PolymarketCLOBService {
        let provider = TangemProvider<PolymarketCLOBTarget>(configuration: networkConfiguration)

        return CommonPolymarketCLOBService(provider: provider, baseURL: PolymarketHost.clob)
    }

    public func makePositionsValueService() -> PolymarketPositionsValueService {
        let provider = TangemProvider<PolymarketPositionsValueTarget>(configuration: networkConfiguration)

        return CommonPolymarketPositionsValueService(provider: provider, baseURL: PolymarketHost.dataAPI)
    }

    public func makeConfigurationService(
        walletId: String,
        store: PolymarketBuilderCodeStore
    ) -> PolymarketConfigurationService {
        let provider = TangemProvider<PolymarketConfigurationTarget>(
            configuration: networkConfiguration,
            additionalPlugins: backendClockPlugins
        )

        return CommonPolymarketConfigurationService(
            provider: provider,
            environment: environment,
            walletId: walletId,
            store: store
        )
    }

    public func makeWithdrawService(walletId: String) -> PolymarketWithdrawService {
        let provider = TangemProvider<PolymarketWithdrawTarget>(
            configuration: networkConfiguration,
            additionalPlugins: backendClockPlugins
        )

        return CommonPolymarketWithdrawService(provider: provider, environment: environment, walletId: walletId)
    }

    public func makeRedeemService(walletId: String) -> PolymarketRedeemService {
        let provider = TangemProvider<PolymarketRedeemTarget>(
            configuration: networkConfiguration,
            additionalPlugins: backendClockPlugins
        )

        return CommonPolymarketRedeemService(provider: provider, environment: environment, walletId: walletId)
    }

    public func makeBridgeService() -> PolymarketBridgeService {
        let provider = TangemProvider<PolymarketBridgeTarget>(configuration: networkConfiguration)

        return CommonPolymarketBridgeService(provider: provider, baseURL: PolymarketHost.bridge)
    }
}
