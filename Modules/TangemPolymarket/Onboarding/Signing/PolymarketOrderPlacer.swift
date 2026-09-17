//
//  PolymarketOrderPlacer.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketOrderDigestSigning {
    func sign(digest: Data) async throws -> String
}

public protocol PolymarketOrderPlacing {
    func place(_ options: PolymarketOrderPlacer.Options) async throws -> PolymarketOrderPlacement

    func order(
        id: String,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderRecord
}

public struct PolymarketOrderPlacer {
    private let clobService: PolymarketCLOBService
    private let digestSigner: PolymarketOrderDigestSigning

    public init(clobService: PolymarketCLOBService, digestSigner: PolymarketOrderDigestSigning) {
        self.clobService = clobService
        self.digestSigner = digestSigner
    }
}

// MARK: - PolymarketOrderPlacing protocol conformance

extension PolymarketOrderPlacer: PolymarketOrderPlacing {
    public func place(_ options: Options) async throws -> PolymarketOrderPlacement {
        let order = PolymarketOrderFactory.make(
            quote: options.quote,
            assetId: options.assetId,
            depositWalletAddress: options.depositWalletAddress
        )

        let signature: String

        do {
            let digest = try PolymarketOrderSigning.digest(
                order: order,
                isNegRisk: options.isNegRisk,
                depositWalletAddress: options.depositWalletAddress
            )

            let inner = try await digestSigner.sign(digest: digest)

            signature = try PolymarketOrderSigning.wrap(
                signature: inner,
                order: order,
                isNegRisk: options.isNegRisk
            )
        } catch let error as CancellationError {
            throw error
        } catch {
            throw PolymarketOrderPlacementError.notSent(underlying: error)
        }

        let signedOrder = PolymarketSignedOrder(
            order: order,
            signature: signature,
            isNegRisk: options.isNegRisk
        )

        return try await clobService.placeOrder(
            signedOrder,
            credentials: options.credentials,
            ownerAddress: options.ownerAddress
        )
    }

    public func order(
        id: String,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderRecord {
        try await clobService.order(id: id, credentials: credentials, ownerAddress: ownerAddress)
    }
}

// MARK: - Options

public extension PolymarketOrderPlacer {
    struct Options {
        public let quote: PolymarketOrderQuote
        public let assetId: String
        public let isNegRisk: Bool
        public let ownerAddress: String
        public let depositWalletAddress: String
        public let credentials: PolymarketL2Credentials

        public init(
            quote: PolymarketOrderQuote,
            assetId: String,
            isNegRisk: Bool,
            ownerAddress: String,
            depositWalletAddress: String,
            credentials: PolymarketL2Credentials
        ) {
            self.quote = quote
            self.assetId = assetId
            self.isNegRisk = isNegRisk
            self.ownerAddress = ownerAddress
            self.depositWalletAddress = depositWalletAddress
            self.credentials = credentials
        }
    }
}
