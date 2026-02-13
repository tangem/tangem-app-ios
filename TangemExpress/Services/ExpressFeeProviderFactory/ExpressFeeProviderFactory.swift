//
//  ExpressFeeProviderFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol ExpressFeeProviderFactory {
    func makeExpressFeeProvider() -> any ExpressFeeProvider
}
