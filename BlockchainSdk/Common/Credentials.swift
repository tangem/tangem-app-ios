//
//  Credentials.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension NetworkProviderConfiguration {
    public struct Credentials: Decodable {
        let user: String
        let password: String

        public init(login: String, password: String) {
            self.user = login
            self.password = password
        }
    }
}
