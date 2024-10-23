//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPaymentMethod: Hashable {
    public let identity: OnrampIdentity

    public init(identity: OnrampIdentity) {
        self.identity = identity
    }
}
