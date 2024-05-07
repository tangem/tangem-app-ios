//
//  WalletConnectCryptoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift
import WalletConnectSwiftV2

struct WalletConnectCryptoProvider: CryptoProvider {
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        #warning("Need to insert implementation")
        return Data()
    }

    public func keccak256(_ data: Data) -> Data {
        return data.sha3(.keccak256)
    }
}
