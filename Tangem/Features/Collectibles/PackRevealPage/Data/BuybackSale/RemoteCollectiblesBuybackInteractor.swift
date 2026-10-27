//
//  RemoteCollectiblesBuybackInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

struct RemoteCollectiblesBuybackInteractor {
    // MARK: - Properties

    private let generator: any CollectiblesBuybackTransactionGenerator
    private let signer: any CollectiblesBuybackSigner
    private let signingLimits: any CollectiblesBuybackSigningLimits
    private let sentReporter: any CollectiblesBuybackSentReporter
    private let statusProvider: any CollectiblesBuybackStatusProvider
    private let delayProvider: any PollDelayProvider

    // MARK: - Init

    init(
        generator: any CollectiblesBuybackTransactionGenerator,
        signer: any CollectiblesBuybackSigner,
        signingLimits: any CollectiblesBuybackSigningLimits,
        sentReporter: any CollectiblesBuybackSentReporter,
        statusProvider: any CollectiblesBuybackStatusProvider,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.generator = generator
        self.signer = signer
        self.signingLimits = signingLimits
        self.sentReporter = sentReporter
        self.statusProvider = statusProvider
        self.delayProvider = delayProvider
    }
}

// MARK: - CollectiblesBuybackInteractor protocol conformance

extension RemoteCollectiblesBuybackInteractor: CollectiblesBuybackInteractor {
    func sell(nftAddress: String, offer: CollectiblesBuybackOffer) async throws {
        guard let addresses = signer.buybackAddresses else {
            throw CollectiblesBuybackSaleError.accountNotReady
        }

        let terms = try CollectiblesBuybackTerms(nftAddress: nftAddress, offer: offer)
        let transaction = try await generate(nftAddress: nftAddress, addresses: addresses)
        let signedBuyback = try await sign(transaction, terms: terms)

        try await send(signedBuyback)
        try await report(signedBuyback, buybackID: transaction.buybackID)
        try await awaitConfirmation(buybackID: transaction.buybackID)
    }
}

// MARK: - Private logic

private extension RemoteCollectiblesBuybackInteractor {
    func generate(
        nftAddress: String,
        addresses: CollectiblesBuybackAddresses
    ) async throws -> CollectiblesBuybackTransaction {
        do {
            return try await generator.generate(
                nftAddress: nftAddress,
                fromAddress: addresses.owner,
                toAddress: addresses.payoutRecipient
            )
        } catch {
            throw Self.saleError(from: error, step: "transaction request")
        }
    }

    func sign(
        _ transaction: CollectiblesBuybackTransaction,
        terms: CollectiblesBuybackTerms
    ) async throws -> CollectiblesSignedBuyback {
        do {
            guard try signingLimits.canSign(transaction.transaction) else {
                throw SigningFailure.transactionTooLarge
            }

            return try await signer.signBuyback(transaction.transaction, terms: terms)
        } catch {
            throw Self.saleError(from: error, step: "signing")
        }
    }

    func send(_ signedBuyback: CollectiblesSignedBuyback) async throws {
        do throws(CollectiblesSendError) {
            try await signer.sendBuyback(signedBuyback)
        } catch {
            switch error {
            case .transactionExpired, .outcomeUnknown:
                CollectiblesLogger.info(
                    "Collectibles buyback \(signedBuyback.signature) send outcome unknown, the backend status decides"
                )
            case .rejected(let rejection):
                throw Self.saleError(from: rejection, step: "sending")
            }
        }
    }

    func report(_ signedBuyback: CollectiblesSignedBuyback, buybackID: String) async throws {
        do {
            try await sentReporter.report(buybackID: buybackID, txHash: signedBuyback.signature)
        } catch let error where error.isCancellationError {
            throw CancellationError()
        } catch {
            CollectiblesLogger.error("Collectibles buyback \(buybackID) sent report failed", error: error)
        }
    }

    func awaitConfirmation(buybackID: String) async throws {
        let polling = PollingSequence(
            interval: Constants.statusCheckInterval,
            request: { [statusProvider] in try await statusProvider.load(buybackID: buybackID) },
            delayProvider: delayProvider
        )

        var checksCount = 0

        for await result in polling {
            checksCount += 1

            switch result {
            case .success(.confirmed):
                return
            case .success(.expired):
                CollectiblesLogger.warning("Collectibles buyback \(buybackID) expired before it was confirmed")
                throw CollectiblesBuybackSaleError.notConfirmed
            case .success:
                break
            case .failure(let error):
                CollectiblesLogger.error("Collectibles buyback \(buybackID) status check failed", error: error)
            }

            guard checksCount < Constants.statusChecksCount else {
                // [REDACTED_TODO_COMMENT]
                throw CollectiblesBuybackSaleError.notConfirmed
            }
        }

        throw CancellationError()
    }

    static func saleError(from error: any Error, step: String) -> any Error {
        guard !error.isCancellationError else {
            return CancellationError()
        }

        CollectiblesLogger.error("Collectibles buyback \(step) failed", error: error)
        return CollectiblesBuybackSaleError.failed
    }
}

// MARK: - Signing failure

private extension RemoteCollectiblesBuybackInteractor {
    enum SigningFailure: Error {
        case transactionTooLarge
    }
}

// MARK: - Constants

private extension RemoteCollectiblesBuybackInteractor {
    enum Constants {
        static let statusCheckInterval: TimeInterval = 2
        static let statusChecksCount = 5
    }
}
