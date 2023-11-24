//
//  ExpressAsset.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressAsset {
    public let currency: ExpressCurrency
    public let token: String
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let exchangeAvailable: Bool
    // Future
    public let onrampAvailable: Bool?
    public let offrampAvailable: Bool?
}
