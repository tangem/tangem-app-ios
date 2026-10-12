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
    private let depositWalletResolver: PolymarketDepositWalletResolver
    private let signer: PolymarketBatchSigning
    private let serverClock: PolymarketServerClock
    private let pollDelayProvider: PollDelayProvider

    private var isWithdrawInProgress = false

    init(
        bridgeService: PolymarketBridgeService,
        configurationService: PolymarketConfigurationService,
        relayerService: PolymarketRelayerService,
        withdrawService: PolymarketWithdrawService,
        depositWalletResolver: PolymarketDepositWalletResolver,
        signer: PolymarketBatchSigning,
        serverClock: PolymarketServerClock,
        pollDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.bridgeService = bridgeService
        self.configurationService = configurationService
        self.relayerService = relayerService
        self.withdrawService = withdrawService
        self.depositWalletResolver = depositWalletResolver
        self.signer = signer
        self.serverClock = serverClock
        self.pollDelayProvider = pollDelayProvider
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

        let batch = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            deadline: makeDeadline(),
            calls: [call]
        )

        let signed = try await signer.sign(batch, as: addresses.owner)

        return try await settledRecord(for: try await submit(signed))
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

    func makeDeadline() -> String {
        String(Int(serverClock.now.timeIntervalSince1970) + Constants.deadlineOffset)
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

    func settledRecord(for record: PolymarketWithdrawRecord) async throws -> PolymarketWithdrawRecord {
        if record.state.isTerminal {
            return try settled(record)
        }

        try? await pollDelayProvider.wait(for: Constants.pollingInterval)

        let polling = PollingSequence(
            interval: Constants.pollingInterval,
            request: { [withdrawService] in try await withdrawService.record(ofWithdrawal: record.transactionId) },
            delayProvider: pollDelayProvider
        )

        var latest = record

        for await result in polling.prefix(Constants.pollingAttempts) {
            guard let polled = result.value else {
                continue
            }

            guard polled.state.isTerminal else {
                latest = polled
                continue
            }

            return try settled(polled)
        }

        return latest
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
            // [REDACTED_TODO_COMMENT]
            case .destinationAssetUnavailable:
                "Polymarket is not accepting USDC on Polygon right now. Please try again later."
            case .bridgeAddressUnavailable:
                "Polymarket did not hand out an address for this withdrawal. Please try again."
            case .transferFailed:
                "The transfer did not go through. Nothing left your account, and you can try again."
            case .refused(let error):
                Self.message(for: error)
            }
        }
    }
}

// MARK: - What the backend's answers mean to a person

private extension PolymarketWithdrawTransactionService.Error {
    // [REDACTED_TODO_COMMENT]
    static func message(for error: PolymarketWithdrawError) -> String {
        switch error {
        case .conflict:
            "Polymarket cannot accept this withdrawal yet. If another one is still running, wait for it to finish and try again."
        case .foreignDepositWallet:
            "This Polymarket account does not belong to this wallet."
        case .notFound:
            "There is no record of this withdrawal."
        case .relayerRejected:
            "Polymarket refused to relay the withdrawal. Please try again."
        case .upstreamUnavailable:
            "Polymarket is unreachable right now. Try again in a few minutes."
        case .unauthorized, .badRequest, .cancelled, .other:
            "The withdrawal could not be sent. Please try again."
        }
    }
}

// MARK: - Constants

private extension PolymarketWithdrawTransactionService {
    enum Constants {
        static let deadlineOffset = 600
        static let pollingInterval: TimeInterval = 3
        static let pollingAttempts = 10
    }
}
