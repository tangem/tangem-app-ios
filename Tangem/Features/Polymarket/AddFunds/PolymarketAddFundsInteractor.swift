//
//  PolymarketAddFundsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketAddFundsInteractor {
    /// The last preparation outcome, kept for the sheet the user opens after the screen has already prepared it.
    var state: State { storedState.withLock { $0 } }

    private let bridgeService: PolymarketBridgeService
    private let configurationService: PolymarketConfigurationService
    private let walletService: PolymarketDepositWalletService
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let walletId: String

    private let storedState = OSAllocatedUnfairLock(initialState: State.loading)

    init(
        bridgeService: PolymarketBridgeService,
        configurationService: PolymarketConfigurationService,
        walletService: PolymarketDepositWalletService,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        walletId: String
    ) {
        self.bridgeService = bridgeService
        self.configurationService = configurationService
        self.walletService = walletService
        self.ownerAddressProvider = ownerAddressProvider
        self.walletId = walletId
    }
}

// MARK: - Preparation

extension PolymarketAddFundsInteractor {
    @discardableResult
    func prepare() async -> State {
        do {
            let builderCode = try await configurationService.builderCode()
            let depositWalletAddress = try await verifiedDepositWalletAddress()
            let assets = try await bridgeService.supportedAssets()

            guard let asset = Self.usdcOnPolygon(in: assets) else {
                PolymarketLogger.warning("Add funds is unavailable: the bridge does not currently accept USDC on Polygon")
                return store(.unavailable)
            }

            let addresses = try await bridgeService.fundingAddresses(
                forDepositWallet: depositWalletAddress,
                builderCode: builderCode
            )

            guard let fundingAddress = addresses.address(for: asset.family) else {
                PolymarketLogger.warning("Add funds is unavailable: the bridge answered without a \(asset.family) funding address")
                return store(.unavailable)
            }

            return store(.available(FundingTarget(asset: asset, fundingAddress: fundingAddress)))
        } catch {
            guard !Task.isCancelled else { return state }

            PolymarketLogger.error("Failed to prepare add funds", error: error)
            return store(.unavailable)
        }
    }
}

// MARK: - Asset lookup

extension PolymarketAddFundsInteractor {
    static func usdcOnPolygon(in assets: [PolymarketSupportedAsset]) -> PolymarketSupportedAsset? {
        guard let polygonChainId = PolymarketUtilities.blockchain.chainId.map(String.init) else {
            return nil
        }

        return assets.first { asset in
            asset.chainId == polygonChainId
                && asset.token.address.caseInsensitiveCompare(PolymarketUtilities.usdcContractAddress) == .orderedSame
        }
    }
}

// MARK: - Private implementation

private extension PolymarketAddFundsInteractor {
    /// A superseded preparation must not overwrite the state of the one that replaced it, and a cancelled
    /// request reaches us as an ordinary connection failure rather than as `CancellationError`.
    func store(_ state: State) -> State {
        guard !Task.isCancelled else { return self.state }

        storedState.withLock { $0 = state }

        return state
    }

    /// The bridge credits the deposit to exactly the address it is given, so the locally derived one is
    /// checked against the backend's record first. Unlike the onboarding run, funding requires that record
    /// to already exist and to be ready to trade: a wallet the backend does not confirm has nowhere to
    /// credit the deposit.
    func verifiedDepositWalletAddress() async throws -> String {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketAddFundsError.ownerKeyUnavailable
        }

        let derived = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)
        let stored = try await walletService.depositWalletState(ownerAddress: ownerAddress, walletId: walletId)

        try stored.ensureMatches(derived: derived)

        guard stored.address != nil, stored.status == .readyToTrade else {
            throw PolymarketAddFundsError.depositWalletNotReadyToTrade(stored.status)
        }

        return derived
    }
}

// MARK: - State

extension PolymarketAddFundsInteractor {
    enum State: Equatable {
        case loading
        case available(FundingTarget)
        case unavailable

        var fundingTarget: FundingTarget? {
            if case .available(let target) = self { return target }
            return nil
        }
    }

    struct FundingTarget: Equatable {
        let asset: PolymarketSupportedAsset
        let fundingAddress: String
    }
}

// MARK: - Errors

enum PolymarketAddFundsError: Error, Equatable {
    case ownerKeyUnavailable
    case depositWalletNotReadyToTrade(PolymarketDepositWalletStatus)
}
