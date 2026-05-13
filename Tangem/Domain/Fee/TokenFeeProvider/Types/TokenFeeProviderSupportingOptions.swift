//
//  TokenFeeProviderSupportingOptions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TokenFeeProviderSupportingOptions {
    static let compound = TokenFeeProviderSupportingOptions.exactly([.market])
    static let swap = TokenFeeProviderSupportingOptions.exactly([.market, .fast])

    case all
    case exactly([FeeOption])
}
