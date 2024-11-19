//
//  OnrampPair.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPair: Hashable {
    public let fiatCurrencyCode: String?
    public let currency: ExpressCurrency
    public let providers: [OnrampProvider]
}
