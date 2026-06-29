//
//  OnrampRedirectData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampRedirectData: Equatable {
    public let txId: String
    public let widgetURL: URL
    public let redirectURL: URL
    public let fromAmount: Decimal
    public let fromCurrencyCode: String
    public let toAmount: Decimal?
    public let countryCode: String
    public let externalTxId: String?
    public let externalTxURL: URL?
}
