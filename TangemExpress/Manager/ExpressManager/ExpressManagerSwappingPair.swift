//
//  ExpressManagerSwappingPair.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressManagerSwappingPair: Hashable {
    public let source: ExpressSourceWallet
    public let destination: ExpressDestinationWallet

    public init(source: ExpressSourceWallet, destination: ExpressDestinationWallet) {
        self.source = source
        self.destination = destination
    }
}
