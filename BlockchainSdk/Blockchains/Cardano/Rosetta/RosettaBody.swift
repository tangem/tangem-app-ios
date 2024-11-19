//
//  RosettaBody.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaAddressBody: Codable {
    let networkIdentifier: RosettaNetworkIdentifier
    let accountIdentifier: RosettaAccountIdentifier
}

struct RosettaSubmitBody: Codable {
    let networkIdentifier: RosettaNetworkIdentifier
    let signedTransaction: String
}
