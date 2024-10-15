//
//  OnrampCurrency.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampCurrency: Hashable {
    public let identity: OnrampIdentity

    public init(identity: OnrampIdentity) {
        self.identity = identity
    }
}
