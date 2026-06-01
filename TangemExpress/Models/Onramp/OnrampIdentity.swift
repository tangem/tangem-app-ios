//
//  OnrampIdentity.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampIdentity: Hashable {
    public let name: String
    public let code: String
    public let image: URL?

    public init(name: String, code: String, image: URL?) {
        self.name = name
        self.code = code
        self.image = image
    }
}
