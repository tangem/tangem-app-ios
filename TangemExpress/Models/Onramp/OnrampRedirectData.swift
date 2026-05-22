//
//  OnrampRedirectData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampRedirectData: Codable, Equatable {
    public let txId: String
    public let widgetUrl: URL
    public let redirectUrl: URL
    public let fromAmount: Decimal
    public let fromCurrencyCode: String
    public let externalTxId: String?
    public let externalTxUrl: String?
}
