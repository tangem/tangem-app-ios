//
//  ExpressManagerSwappingPair.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressManagerSwappingPair: Hashable {
    public let source: ExpressWallet
    public let destination: ExpressWallet

    public init(source: ExpressWallet, destination: ExpressWallet) {
        self.source = source
        self.destination = destination
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(source.currency)
        hasher.combine(destination.currency)
    }

    public static func == (lhs: ExpressManagerSwappingPair, rhs: ExpressManagerSwappingPair) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
