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

    public init(source: any ExpressSourceWallet, destination: any ExpressDestinationWallet) {
        self.source = source
        self.destination = destination
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
