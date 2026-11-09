//
//  CollectiblesAccountDerivationPathBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct CollectiblesAccountDerivationPathBuilder {}

// MARK: - AccountDerivationPathBuilder protocol conformance

extension CollectiblesAccountDerivationPathBuilder: AccountDerivationPathBuilder {
    func makeDerivationPath(basedOn derivationPath: DerivationPath?, for blockchain: Blockchain) -> DerivationPath? {
        nil
    }

    func getTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath? {
        nil
    }

    func validateDerivationPath(
        _ derivationPath: DerivationPath?,
        for blockchain: Blockchain
    ) throws(AccountDerivationPathError) {
        throw .accountsUnavailableForBlockchain(blockchain.displayName)
    }
}
