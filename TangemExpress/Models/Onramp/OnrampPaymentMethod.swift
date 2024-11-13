//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPaymentMethod: Hashable {
    public let id: String
    public let name: String
    public let image: URL?

    public init(id: String, name: String, image: URL?) {
        self.id = id
        self.name = name
        self.image = image
    }
}
