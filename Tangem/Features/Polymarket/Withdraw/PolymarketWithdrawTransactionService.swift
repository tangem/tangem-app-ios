//
//  PolymarketWithdrawTransactionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemPolymarket

actor PolymarketWithdrawTransactionService {
    private let bridgeService: PolymarketBridgeService
    private let configurationService: PolymarketConfigurationService
    private let relayerService: PolymarketRelayerService
    private let withdrawService: PolymarketWithdrawService
    private let tracker: any PolymarketWithdrawTracking
    private let depositWalletResolver: PolymarketDepositWalletResolver
    private let signer: PolymarketBatchSigning
    private let serverClock: PolymarketServerClock

    private var isWithdrawInProgress = false

    init(
        bridgeService: PolymarketBridgeService,
        configurationService: PolymarketConfigurationService,
        relayerService: PolymarketRelayerService,
        withdrawService: PolymarketWithdrawService,
        tracker: any PolymarketWithdrawTracking,
        depositWalletResolver: PolymarketDepositWalletResolver,
        signer: PolymarketBatchSigning,
        serverClock: PolymarketServerClock
    ) {
        self.bridgeService = bridgeService
        self.configurationService = configurationService
        self.relayerService = relayerService
        self.withdrawService = withdrawService
        self.tracker = tracker
        self.depositWalletResolver = depositWalletResolver
        self.signer = signer
        self.serverClock = serverClock
    }
}

// MARK: - PolymarketWithdrawing protocol conformance

extension PolymarketWithdrawTransactionService: PolymarketWithdrawing {
    func withdraw(amount: Decimal, to recipientAddress: String) async throws -> PolymarketWithdrawRecord {
        do {
            return try await performWithdraw(amount: amount, to: recipientAddress)
        } catch {
            throw presentable(error)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketWithdrawTransactionService {
    func presentable(_ error: Swift.Error) -> Swift.Error {
        if Task.isCancelled {
            return CancellationError()
        }

        switch error {
        case let failure as Error:
            return failure

        case let signingFailure as PolymarketSigningError:
            if case .cancelled = signingFailure {
                return CancellationError()
            }

            PolymarketLogger.error("The withdrawal was never signed", error: signingFailure)

            return Error.notSigned

        case let refusal as PolymarketWithdrawError:
            PolymarketLogger.error("The backend refused the withdrawal", error: refusal)

            return Error.refused(refusal)

        default:
            PolymarketLogger.error("The withdrawal was never prepared", error: error)

            return Error.preparationFailed
        }
    }

    func performWithdraw(amount: Decimal, to recipientAddress: String) async throws -> PolymarketWithdrawRecord {
        guard !isWithdrawInProgress else {
            throw Error.withdrawInProgress
        }

        isWithdrawInProgress = true

        defer { isWithdrawInProgress = false }

        let addresses = try await depositWalletResolver.resolve()
        let builderCode = try await configurationService.builderCode()

        let bridgeAddress = try await bridgeAddress(
            forDepositWallet: addresses.depositWallet,
            recipientAddress: recipientAddress,
            builderCode: builderCode
        )

        let amountBaseUnits = try makeAmountBaseUnits(from: amount)
        let call = try makeCall(to: bridgeAddress, amountBaseUnits: amountBaseUnits)
        let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)
        let deadline = makeDeadline()

        let batch = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            deadline: String(Int(deadline.timeIntervalSince1970)),
            calls: [call]
        )

        let signed = try await signer.sign(batch, as: addresses.owner)
        let record = try await submit(signed)

        await tracker.track(record, deadline: deadline)

        return try settled(record)
    }

    func bridgeAddress(
        forDepositWallet depositWalletAddress: String,
        recipientAddress: String,
        builderCode: String
    ) async throws -> String {
        let assets = try await bridgeService.supportedAssets()

        guard let asset = PolymarketDepositAssetCatalog.acceptedAsset(
            for: PolymarketDepositAssetCatalog.usdcOnPolygon,
            in: assets
        ) else {
            throw Error.destinationAssetUnavailable
        }

        let route = PolymarketWithdrawRoute(
            destinationChainId: asset.chainId,
            destinationTokenAddress: asset.token.address,
            recipientAddress: recipientAddress
        )

        let addresses = try await bridgeService.withdrawAddresses(
            forDepositWallet: depositWalletAddress,
            route: route,
            builderCode: builderCode
        )

        guard let bridgeAddress = addresses.address(for: .evm) else {
            throw Error.bridgeAddressUnavailable
        }

        return bridgeAddress
    }

    func makeAmountBaseUnits(from amount: Decimal) throws -> BigUInt {
        let baseUnits = amount
            .moveRight(decimals: PolymarketCollateral.decimalCount)
            .rounded(scale: 0, roundingMode: .down)

        guard let amountBaseUnits = BigUInt(decimal: baseUnits), amountBaseUnits > 0 else {
            throw Error.amountNotRepresentable
        }

        return amountBaseUnits
    }

    func makeCall(to bridgeAddress: String, amountBaseUnits: BigUInt) throws -> PolymarketRelayedBatch.Call {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: amountBaseUnits)

        guard PolymarketWithdrawCall.carries(call, transferOf: amountBaseUnits, to: bridgeAddress) else {
            throw Error.calldataMismatch
        }

        return call
    }

    func makeDeadline() -> Date {
        Date(timeIntervalSince1970: TimeInterval(Int(serverClock.now.timeIntervalSince1970) + Constants.deadlineOffset))
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws -> PolymarketWithdrawRecord {
        do {
            return try await withdrawService.submit(batch)
        } catch {
            guard case .other(.connection) = error else {
                throw error
            }

            PolymarketLogger.warning("The withdrawal submission got no answer, resending the same batch")

            return try await withdrawService.submit(batch)
        }
    }

    func settled(_ record: PolymarketWithdrawRecord) throws -> PolymarketWithdrawRecord {
        guard record.state != .failed else {
            throw Error.transferFailed(record)
        }

        return record
    }
}

// MARK: - Errors

extension PolymarketWithdrawTransactionService {
    enum Error: LocalizedError {
        case withdrawInProgress
        case destinationAssetUnavailable
        case bridgeAddressUnavailable
        case amountNotRepresentable
        case calldataMismatch
        case notSigned
        case preparationFailed
        case transferFailed(PolymarketWithdrawRecord)
        case refused(PolymarketWithdrawError)

        var errorDescription: String? {
            switch self {
            case .withdrawInProgress, .amountNotRepresentable, .calldataMismatch, .notSigned, .preparationFailed:
                Localization.sendWithSwapSomethingWentWrong
            case .destinationAssetUnavailable:
                Localization.predictionWithdrawErrorAssetUnavailable
            case .bridgeAddressUnavailable:
                Localization.predictionWithdrawErrorAddressUnavailable
            case .transferFailed:
                Localization.predictionWithdrawStatusFailedDescription
            case .refused(let error):
                Self.message(for: error)
            }
        }
    }
}

// MARK: - What the backend's answers mean to a person

private extension PolymarketWithdrawTransactionService.Error {
    static func message(for error: PolymarketWithdrawError) -> String {
        switch error {
        case .conflict:
            Localization.predictionWithdrawInProgressMessage
        case .foreignDepositWallet:
            Localization.predictionWithdrawErrorForeignAccount
        case .relayerRejected:
            Localization.predictionWithdrawErrorRejected
        case .upstreamUnavailable:
            Localization.predictionClaimErrorUnavailable
        case .notFound, .unauthorized, .badRequest, .cancelled, .other:
            Localization.predictionWithdrawErrorGeneric
        }
    }
}

// MARK: - Constants

private extension PolymarketWithdrawTransactionService {
    enum Constants {
        static let deadlineOffset = 600
    }
}
