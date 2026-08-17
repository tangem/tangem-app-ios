//
//  ExpressManagerSwappingPair.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressManagerSwappingPair {
    public let source: any ExpressSourceWallet
    public let destination: any ExpressDestinationWallet

    /// The factor between the amounts shown to the user and the amounts the chain operates on for the
    /// source token, or `nil` when the two coincide. Resolved before the pair is handed over so that
    /// amounts can be converted without further I/O.
    public let sourceAmountScale: Decimal?

    public var isTransfer: Bool { source.currency == destination.currency }

    public init(
        source: any ExpressSourceWallet,
        destination: any ExpressDestinationWallet,
        sourceAmountScale: Decimal? = nil
    ) {
        self.source = source
        self.destination = destination
        self.sourceAmountScale = sourceAmountScale
    }

    public func currencySymbol(for amountType: ExpressAmountType) -> String {
        switch amountType {
        case .from:
            return source.currency.symbol
        case .to:
            return destination.currency.symbol
        }
    }
}
