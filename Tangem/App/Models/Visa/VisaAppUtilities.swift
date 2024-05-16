//
//  VisaAppUtilities.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemVisa

struct VisaAppUtilities {
    var blockchainNetwork: BlockchainNetwork {
        .init(VisaUtilities().visaBlockchain, derivationPath: nil)
    }

    private var curve: EllipticCurve {
        .secp256k1
    }

    func getPublicKeyData(from list: [CardDTO.Wallet]) -> Data? {
        list.first(where: { $0.curve == curve })?.publicKey
    }

    func makeBSDKPublicKey(using list: [CardDTO.Wallet]) -> Wallet.PublicKey? {
        guard let pubKey = getPublicKeyData(from: list) else {
            return nil
        }

        return .init(seedKey: pubKey, derivationType: .none)
    }
}
