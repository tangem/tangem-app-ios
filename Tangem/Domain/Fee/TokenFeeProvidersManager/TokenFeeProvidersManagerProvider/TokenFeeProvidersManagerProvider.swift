//
//  TokenFeeProvidersManagerProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol TokenFeeProvidersManagerProvider: ExpressFeeProviderFactory {
    func makeTokenFeeProvidersManager() -> TokenFeeProvidersManager
}

extension TokenFeeProvidersManagerProvider {
    func makeExpressFeeProvider() -> any ExpressFeeProvider {
        makeTokenFeeProvidersManager()
    }
}
