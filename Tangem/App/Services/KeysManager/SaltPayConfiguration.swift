//
//  SaltPayConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SaltPayConfiguration: Decodable {
    let zendesk: ZendeskConfig
    let kycProvider: KYCProvider
    let credentials: NetworkProviderConfiguration.Credentials
}

struct KYCProvider: Decodable {
    let baseUrl: String
    let externalIdParameterKey: String
    let sidParameterKey: String
    let sidValue: String
}
