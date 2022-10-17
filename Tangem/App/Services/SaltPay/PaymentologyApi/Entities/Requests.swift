//
//  ReqisterWalletRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReqisterWalletRequest: Codable {
    let cardId: String
    let publicKey: Data
    let walletPublicKey: Data
    let walletSalt: Data
    let walletSignature: Data
    let cardSalt: Data
    let cardSignature: Data
    let pin: String

    enum CodingKeys: String, CodingKey {
        case cardId = "CID"
        case publicKey
        case walletPublicKey
        case walletSalt
        case walletSignature
        case cardSalt
        case cardSignature
        case pin = "PIN"
    }
}

struct RegisterKYCRequest: Codable {
    let cardId: String
    let publicKey: Data
    let kycProvider: String
    let kycRefId: String

    enum CodingKeys: String, CodingKey {
        case cardId = "CID"
        case publicKey
        case kycProvider
        case kycRefId
    }
}
