//
//  PolymarketAccountFundsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket

final class PolymarketAccountFundsInteractor {
    var state: State { storedState.withLock { $0 } }

    private let bridgeService: PolymarketBridgeService
    private let configurationService: PolymarketConfigurationService
    private let walletService: PolymarketDepositWalletService
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let supportedBlockchains: Set<Blockchain>

    private let storedState = OSAllocatedUnfairLock(initialState: State.loading)

    init(
        bridgeService: PolymarketBridgeService,
        configurationService: PolymarketConfigurationService,
        walletService: PolymarketDepositWalletService,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        supportedBlockchains: Set<Blockchain>
    ) {
        self.bridgeService = bridgeService
        self.configurationService = configurationService
        self.walletService = walletService
        self.ownerAddressProvider = ownerAddressProvider
        self.supportedBlockchains = supportedBlockchains
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

            let assets = await bridgeAssets
            let depositTargets = depositTargets(assets: assets, addresses: await bridgeAddresses)

            return store(.ready(Readiness(
                depositWalletAddress: depositWalletAddress,
                depositTargets: depositTargets,
                collateralMinCheckoutUSD: collateralMinCheckoutUSD(in: assets)
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

    func depositTargets(
        assets: [PolymarketSupportedAsset]?,
        addresses: PolymarketBridgeAddresses?
    ) -> [DepositTarget] {
        guard let assets, let addresses else {
            return []
        }

        let acceptedAssets = PolymarketDepositAssetCatalog.acceptedAssets(from: assets)

        guard !acceptedAssets.isEmpty else {
            PolymarketLogger.warning("A deposit is unavailable: the bridge accepts none of the assets the app offers")
            return []
        }

        return makeDepositTargets(from: acceptedAssets, addresses: addresses)
    }

    /// The withdrawal floor is a fact of the bridge, so it must not depend on anything that
    /// narrows the deposit side — wallet support, funding addresses, the catalog's ordering.
    func collateralMinCheckoutUSD(in assets: [PolymarketSupportedAsset]?) -> Decimal? {
        guard let assets else {
            return nil
        }

        return PolymarketDepositAssetCatalog
            .acceptedAsset(for: PolymarketDepositAssetCatalog.usdcOnPolygon, in: assets)?
            .minCheckoutUSD
    }

    func makeDepositTargets(
        from acceptedAssets: [PolymarketDepositAssetCatalog.AcceptedAsset],
        addresses: PolymarketBridgeAddresses
    ) -> [DepositTarget] {
        var targets: [DepositTarget] = []
        var familiesWithoutAddress = Set<PolymarketChainFamily>()
        var networksTheWalletCannotUse = Set<String>()

        for acceptedAsset in acceptedAssets {
            guard let tokenItem = acceptedAsset.entry.makeTokenItem(supportedBlockchains: supportedBlockchains) else {
                networksTheWalletCannotUse.insert(acceptedAsset.entry.networkId)
                continue
            }

            guard let fundingAddress = addresses.address(for: acceptedAsset.bridgeAsset.family) else {
                familiesWithoutAddress.insert(acceptedAsset.bridgeAsset.family)
                continue
            }

            targets.append(DepositTarget(
                entry: acceptedAsset.entry,
                tokenItem: tokenItem,
                minCheckoutUSD: acceptedAsset.bridgeAsset.minCheckoutUSD,
                fundingAddress: fundingAddress
            ))
        }

        if !networksTheWalletCannotUse.isEmpty {
            PolymarketLogger.warning(
                "The wallet supports none of these networks the bridge accepts: "
                    + networksTheWalletCannotUse.sorted().joined(separator: ", ")
            )
        }

        if !familiesWithoutAddress.isEmpty {
            PolymarketLogger.warning(
                "The bridge answered without a funding address for: "
                    + familiesWithoutAddress.map { "\($0)" }.sorted().joined(separator: ", ")
            )
        }

        if targets.isEmpty {
            PolymarketLogger.warning("A deposit is unavailable: nothing the bridge accepts survived both checks above")
        }

        return targets
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

        var depositTargets: [DepositTarget] {
            if case .ready(let readiness) = self { return readiness.depositTargets }
            return []
        }

        var collateralMinCheckoutUSD: Decimal? {
            if case .ready(let readiness) = self { return readiness.collateralMinCheckoutUSD }
            return nil
        }

        var depositWalletAddress: String? {
            if case .ready(let readiness) = self { return readiness.depositWalletAddress }
            return nil
        }
    }

    struct Readiness: Equatable {
        let depositWalletAddress: String
        let depositTargets: [DepositTarget]
        let collateralMinCheckoutUSD: Decimal?
    }

    struct DepositTarget: Equatable {
        let entry: PolymarketDepositAssetCatalog.Entry
        let tokenItem: TokenItem
        let minCheckoutUSD: Decimal
        let fundingAddress: String
    }
}

// MARK: - Errors

enum PolymarketAccountFundsError: Error, Equatable {
    case ownerKeyUnavailable
    case depositWalletNotReadyToTrade(PolymarketDepositWalletStatus)
}
