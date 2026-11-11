//
//  PolymarketOrderPlacer.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public protocol PolymarketOrderDigestSigning {
    func sign(digest: Data) async throws -> String
}

public protocol PolymarketOrderPlacing {
    func place(_ options: PolymarketOrderPlacer.Options) async throws -> PolymarketOrderPlacement

    func order(
        id: String,
        credentials: PolymarketL2Credentials,
        signingKeyAddress: String
    ) async throws -> PolymarketOrderRecord
}

public struct PolymarketOrderPlacer {
    private let clobService: PolymarketCLOBService
    private let signing: Signing
    private let delayProvider: PollDelayProvider

    public init(
        clobService: PolymarketCLOBService,
        signing: Signing,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.clobService = clobService
        self.signing = signing
        self.delayProvider = delayProvider
    }
}

// MARK: - PolymarketOrderPlacing protocol conformance

extension PolymarketOrderPlacer: PolymarketOrderPlacing {
    public func place(_ options: Options) async throws -> PolymarketOrderPlacement {
        let domain: PolymarketExchangeDomain

        do {
            domain = try PolymarketExchange.domain(for: options.quote, isNegRisk: options.isNegRisk)
        } catch {
            PolymarketLogger.error("Refused to sign an order for an exchange the quote does not match", error: error)
            throw PolymarketOrderPlacementError.notSent(underlying: error)
        }

        let order = PolymarketOrderFactory.make(
            quote: options.quote,
            assetId: options.assetId,
            depositWalletAddress: options.depositWalletAddress
        )

        let signature: String

        do {
            let digest = try PolymarketOrderSigning.digest(
                order: order,
                domain: domain,
                depositWalletAddress: options.depositWalletAddress
            )

            let inner = try await signing.digestSigner.sign(digest: digest)

            let wrapped = try PolymarketOrderSigning.wrap(
                signature: inner,
                order: order,
                domain: domain
            )

            switch signing {
            case .depositWallet:
                signature = wrapped
            case .sessionKey:
                signature = try PolymarketSessionKeySignature.envelope(
                    depositWalletSignature: wrapped,
                    sessionKeyAddress: options.signingKeyAddress
                )
            }
        } catch let error as CancellationError {
            throw error
        } catch {
            throw PolymarketOrderPlacementError.notSent(underlying: error)
        }

        if options.quote.side == .sell {
            try await refreshPositionBalance(options)
        }

        return try await send(
            PolymarketSignedOrder(order: order, signature: signature),
            options: options,
            resendLimit: signing.resendLimit
        )
    }

    public func order(
        id: String,
        credentials: PolymarketL2Credentials,
        signingKeyAddress: String
    ) async throws -> PolymarketOrderRecord {
        try await clobService.order(id: id, credentials: credentials, ownerAddress: signingKeyAddress)
    }
}

// MARK: - Private implementation

private extension PolymarketOrderPlacer {
    enum Constants {
        static let sessionKeyResendLimit = 2
        static let resendDelaySeconds: TimeInterval = 1
    }

    func send(
        _ signedOrder: PolymarketSignedOrder,
        options: Options,
        resendLimit: Int
    ) async throws -> PolymarketOrderPlacement {
        var resends = 0

        while true {
            do {
                return try await clobService.placeOrder(
                    signedOrder,
                    credentials: options.credentials,
                    ownerAddress: options.signingKeyAddress
                )
            } catch let error as PolymarketOrderPlacementError where error.neverReachedTheExchange && resends < resendLimit {
                resends += 1
                PolymarketLogger.warning("The signed order never reached the exchange, sending the same order again (\(resends) of \(resendLimit))")
                try await delayProvider.wait(for: Constants.resendDelaySeconds)
                try Task.checkCancellation()
            } catch PolymarketOrderPlacementError.rejected(let message) where resends > 0 {
                PolymarketLogger.warning("The exchange refused a resent order, an earlier copy of it may already be on the book")
                throw PolymarketOrderPlacementError.ambiguous(underlying: PolymarketOrderPlacementError.rejected(message: message))
            }
        }
    }

    func refreshPositionBalance(_ options: Options) async throws {
        guard let asset = PolymarketBalanceAllowanceAsset.position(tokenId: options.assetId, version: options.quote.version) else {
            return
        }

        do {
            try await clobService.updateBalanceAllowance(
                asset,
                credentials: options.credentials,
                ownerAddress: options.signingKeyAddress
            )
        } catch let error as CancellationError {
            throw error
        } catch {
            PolymarketLogger.error("Failed to refresh the exchange's view of the position before selling", error: error)
        }
    }
}

// MARK: - Options

public extension PolymarketOrderPlacer {
    struct Options {
        public let quote: PolymarketOrderQuote
        public let assetId: String
        public let isNegRisk: Bool
        public let signingKeyAddress: String
        public let depositWalletAddress: String
        public let credentials: PolymarketL2Credentials

        public init(
            quote: PolymarketOrderQuote,
            assetId: String,
            isNegRisk: Bool,
            signingKeyAddress: String,
            depositWalletAddress: String,
            credentials: PolymarketL2Credentials
        ) {
            self.quote = quote
            self.assetId = assetId
            self.isNegRisk = isNegRisk
            self.signingKeyAddress = signingKeyAddress
            self.depositWalletAddress = depositWalletAddress
            self.credentials = credentials
        }
    }

    enum Signing {
        case depositWallet(PolymarketOrderDigestSigning)
        case sessionKey(PolymarketOrderDigestSigning)
    }
}

// MARK: - Signing

private extension PolymarketOrderPlacer.Signing {
    var digestSigner: PolymarketOrderDigestSigning {
        switch self {
        case .depositWallet(let signer), .sessionKey(let signer):
            signer
        }
    }

    var resendLimit: Int {
        switch self {
        case .depositWallet: 0
        case .sessionKey: PolymarketOrderPlacer.Constants.sessionKeyResendLimit
        }
    }
}

private extension PolymarketOrderPlacementError {
    var neverReachedTheExchange: Bool {
        guard case .notSent(let underlying) = self else { return false }

        return (underlying as? PolymarketAPIError)?.neverReachedTheServer == true
    }
}
