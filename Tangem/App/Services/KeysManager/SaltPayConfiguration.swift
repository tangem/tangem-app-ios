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
    let sprinklr: SprinklrProvider
    let kycProvider: KYCProvider
    let credentials: NetworkProviderConfiguration.Credentials
    let blockscoutCredentials: NetworkProviderConfiguration.Credentials
}

struct KYCProvider: Decodable {
    let baseUrl: String
    let externalIdParameterKey: String
    let sidParameterKey: String
    let sidValue: String
}

struct SprinklrProvider: Decodable {
    let appID: String
    let baseURL: String
}
