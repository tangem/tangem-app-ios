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
    func makeAddress(using list: [WalletPublicInfo]) -> Address? {
        // - NOTE: We need to use this isTestnet = false, because in BlockchainSdk we have if for testnet `DerivationPath` generation
        // that didn't work properly, and for Visa we must generate derive keys using polygon derivation
        let utils = VisaUtilities(isTestnet: false)
        guard let wallet = list.first(where: { $0.curve == utils.mandatoryCurve }) else {
            return nil
        }

        guard
            let derivationPath = utils.visaDefaultDerivationPath,
            let extendedPubKey = wallet.derivedKeys[derivationPath],
            let address = try? utils.makeAddress(seedKey: wallet.publicKey, extendedKey: extendedPubKey)
        else {
            return nil
        }

        return address
    }
}
