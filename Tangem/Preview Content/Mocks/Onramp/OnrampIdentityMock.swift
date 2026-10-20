//
//  OnrampIdentityMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

extension OnrampIdentity {
    static let usd = OnrampIdentity(name: "USD", code: "USD", image: IconURLBuilder().fiatIconURL(currencyCode: "USD"))
    static let eur = OnrampIdentity(name: "Euro", code: "EUR", image: IconURLBuilder().fiatIconURL(currencyCode: "EUR"))
}
