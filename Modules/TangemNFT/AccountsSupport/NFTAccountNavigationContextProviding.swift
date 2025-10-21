//
//  NFTAccountNavigationContextProviding.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public protocol NFTAccountNavigationContextProviding {
    func provide(for accountID: AnyHashable) -> NFTNavigationContext?
}
