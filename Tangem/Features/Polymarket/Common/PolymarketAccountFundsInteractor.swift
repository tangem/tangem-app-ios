//
//  PolymarketAccountFundsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketAccountFundsInteractor {
    var state: State { storedState.withLock { $0 } }

    private let bridgeService: PolymarketBridgeService
    private let configurationService: PolymarketConfigurationService
    private let walletService: PolymarketDepositWalletService
    private let ownerAddressProvider: PolymarketOwnerAddressProviding

    private let storedState = OSAllocatedUnfairLock(initialState: State.loading)

    init(
        bridgeService: PolymarketBridgeService,
        configurationService: PolymarketConfigurationService,
        walletService: PolymarketDepositWalletService,
        ownerAddressProvider: PolymarketOwnerAddressProviding
    ) {
        self.bridgeService = bridgeService
        self.configurationService = configurationService
        self.walletService = walletService
        self.ownerAddressProvider = ownerAddressProvider
    }
}

// MARK: - Preparation

extension PolymarketAccountFundsInteractor {
    @discardableResult
    func prepare() async -> State {
        do {
            async let builderCode = configurationService.builderCode()
            async let verifiedAddress = verifiedDepositWalletAddress()

            let depositWalletAddress = try await verifiedAddress
            let resolvedBuilderCode = try await builderCode

            async let bridgeAssets = acceptedAssets()
            async let bridgeAddresses = fundingAddresses(
                forDepositWallet: depositWalletAddress,
                builderCode: resolvedBuilderCode
            )

            let depositTarget = depositTarget(assets: await bridgeAssets, addresses: await bridgeAddresses)

            return store(.ready(Readiness(
                depositWalletAddress: depositWalletAddress,
                depositTarget: depositTarget
            )))
        } catch {
            guard !Task.isCancelled else { return state }

            PolymarketLogger.error("Failed to prepare the Polymarket funding flows", error: error)
            return store(.unavailable)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketAccountFundsInteractor {
    func store(_ state: State) -> State {
        guard !Task.isCancelled else { return self.state }

        storedState.withLock { $0 = state }

        return state
    }

    func acceptedAssets() async -> [PolymarketSupportedAsset]? {
        do {
            return try await bridgeService.supportedAssets()
        } catch {
            PolymarketLogger.error("Failed to read the assets the bridge accepts", error: error)
            return nil
        }
    }

    func fundingAddresses(
        forDepositWallet depositWalletAddress: String,
        builderCode: String
    ) async -> PolymarketBridgeAddresses? {
        do {
            return try await bridgeService.fundingAddresses(
                forDepositWallet: depositWalletAddress,
                builderCode: builderCode
            )
        } catch {
            PolymarketLogger.error("Failed to prepare a Polymarket deposit", error: error)
            return nil
        }
    }

    func depositTarget(
        assets: [PolymarketSupportedAsset]?,
        addresses: PolymarketBridgeAddresses?
    ) -> DepositTarget? {
        guard let assets, let addresses else {
            return nil
        }

        guard let asset = PolymarketUtilities.usdcOnPolygon(in: assets) else {
            PolymarketLogger.warning("A deposit is unavailable: the bridge does not currently accept USDC on Polygon")
            return nil
        }

        guard let fundingAddress = addresses.address(for: asset.family) else {
            PolymarketLogger.warning("A deposit is unavailable: the bridge answered without a \(asset.family) funding address")
            return nil
        }

        return DepositTarget(asset: asset, fundingAddress: fundingAddress)
    }

    func verifiedDepositWalletAddress() async throws -> String {
        let resolver = PolymarketDepositWalletResolver(
            walletService: walletService,
            ownerAddressProvider: ownerAddressProvider
        )

        return try await resolver.resolve().depositWallet
    }
}

// MARK: - State

extension PolymarketAccountFundsInteractor {
    enum State: Equatable {
        case loading
        case ready(Readiness)
        case unavailable

        var depositTarget: DepositTarget? {
            if case .ready(let readiness) = self { return readiness.depositTarget }
            return nil
        }

        var depositWalletAddress: String? {
            if case .ready(let readiness) = self { return readiness.depositWalletAddress }
            return nil
        }
    }

    struct Readiness: Equatable {
        let depositWalletAddress: String
        let depositTarget: DepositTarget?
    }

    struct DepositTarget: Equatable {
        let asset: PolymarketSupportedAsset
        let fundingAddress: String
    }
}

// MARK: - Errors

enum PolymarketAccountFundsError: Error, Equatable {
    case ownerKeyUnavailable
    case depositWalletNotReadyToTrade(PolymarketDepositWalletStatus)
}
