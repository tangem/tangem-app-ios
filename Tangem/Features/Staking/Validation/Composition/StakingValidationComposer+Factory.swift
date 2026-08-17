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
        verifier: StakingTransactionVerifier
    ) -> StakingTransactionValidator? {
        let localValidator = makeLocalValidator(blockchain: blockchain)
        let remoteValidator = makeRemoteValidator(
            blockchain: blockchain,
            accountAddress: accountAddress,
            verifier: verifier
        )

        guard localValidator != nil || remoteValidator != nil else {
            return nil
        }

        return StakingValidationComposer(
            localValidator: localValidator,
            remoteValidator: remoteValidator
        )
    }
}

// MARK: - Private

private extension StakingValidationComposer {
    static func makeLocalValidator(blockchain: Blockchain) -> LocalStakingTransactionValidator? {
        guard let network = LocalStakingSupportedNetwork(blockchain: blockchain), !network.isEthPolValidationDisabled else {
            return nil
        }

        return LocalStakingTransactionValidator(network: network)
    }

    static func makeRemoteValidator(
        blockchain: Blockchain,
        accountAddress: String,
        verifier: StakingTransactionVerifier
    ) -> RemoteStakingTransactionValidator? {
        guard let network = RemoteValidationNetwork(blockchain: blockchain) else {
            return nil
        }

        return RemoteStakingTransactionValidator(
            network: network,
            accountAddress: accountAddress,
            verifier: verifier
        )
    }
}

// MARK: - Private helpers

private extension LocalStakingSupportedNetwork {
    var isEthPolValidationDisabled: Bool {
        self == .ethereumPOL && !FeatureProvider.isAvailable(.ethPolLocalStakingValidation)
    }
}
