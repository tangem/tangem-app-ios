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
    private let utils: VisaUtilities

    init() {
        utils = .init()
    }

    var blockchainNetwork: BlockchainNetwork {
        .init(utils.visaBlockchain, derivationPath: utils.visaDefaultDerivationPath)
    }

    func getPublicKeyData(from list: [CardDTO.Wallet]) -> Data? {
        list.first(where: { $0.curve == utils.mandatoryCurve })?.publicKey
    }

    func makeBlockchainKey(using list: [CardDTO.Wallet]) -> Wallet.PublicKey? {
        guard let pubKey = getPublicKeyData(from: list) else {
            return nil
        }

        return .init(seedKey: pubKey, derivationType: .none)
    }
}
