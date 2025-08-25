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
    func makeAddress(using list: [KeyInfo]) -> Address? {
        // - NOTE: We need to use this isTestnet = false, because in BlockchainSdk we have if for testnet `DerivationPath` generation
        // that didn't work properly, and for Visa we must generate derive keys using polygon derivation
        let utils = VisaUtilities(isTestnet: false)
        guard let wallet = list.first(where: { $0.curve == utils.mandatoryCurve }) else {
            return nil
        }

        return try? utils.makeAddress(walletPublicKey: wallet.publicKey)
    }
}
