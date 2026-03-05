//
//  ExpressPairProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct ExpressPairProvider: Hashable {
    public let id: ExpressProvider.Id
    public let rates: [ExpressProviderRateType]
}
