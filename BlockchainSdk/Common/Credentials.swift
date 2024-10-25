//
//  Credentials.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public extension NetworkProviderConfiguration {
    struct Credentials: Decodable {
        let user: String
        let password: String

        public init(login: String, password: String) {
            user = login
            self.password = password
        }
    }
}
