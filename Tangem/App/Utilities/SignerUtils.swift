//
//  SignerUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignerUtils {
    private static var issuers: [KeyPair] = {
        let path = Bundle.main.url(forResource: "issuers", withExtension: "json")!
        let fileData = try! Data(contentsOf: path)
        return try! JSONDecoder.tangemSdkDecoder.decode([KeyPair].self, from: fileData)
    }()
    
    static func signerKeys(for issuer: String) -> KeyPair? {
        return issuers.first(where: {$0.id.lowercased() == issuer.lowercased()})
    }
    
    static func signerKeys(for publicKey: Data) -> KeyPair? {
        return issuers.first(where: {$0.publicKey == publicKey})
    }
}

struct KeyPair: Equatable, Codable {
    let id: String
    let privateKey: Data
    let publicKey: Data
}
