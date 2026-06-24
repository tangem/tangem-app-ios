//
//  StakingValidationComposer+Factory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension StakingValidationComposer {
    static func make(
        blockchain: Blockchain,
        accountAddress: String,
        verifier: BlockaidStakingVerifier
    ) -> StakingTransactionValidator {
        StakingValidationComposer(
            localValidator: makeLocalValidator(blockchain: blockchain),
            remoteValidator: makeRemoteValidator(
                blockchain: blockchain,
                accountAddress: accountAddress,
                verifier: verifier
            )
        )
    }
}

// MARK: - Private

private extension StakingValidationComposer {
    static func makeLocalValidator(blockchain: Blockchain) -> LocalStakingTransactionValidator? {
        guard let network = LocalStakingSupportedNetwork(blockchain: blockchain) else {
            return nil
        }

        return LocalStakingTransactionValidator(network: network)
    }

    static func makeRemoteValidator(
        blockchain: Blockchain,
        accountAddress: String,
        verifier: BlockaidStakingVerifier
    ) -> RemoteStakingTransactionValidator? {
        guard let network = BlockaidSupportedNetwork(blockchain: blockchain) else {
            return nil
        }

        return RemoteStakingTransactionValidator(
            network: network,
            accountAddress: accountAddress,
            verifier: verifier
        )
    }
}
