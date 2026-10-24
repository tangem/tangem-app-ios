//
//  JointAccountSignaturesCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class JointAccountSignaturesCompactViewModel: ObservableObject {
    @Published private(set) var includesSetupFee = false

    let policy: JointAccountPolicy

    init(policy: JointAccountPolicy, input: SendFeeInput) {
        self.policy = policy

        bind(input: input)
    }

    private func bind(input: SendFeeInput) {
        input.selectedFeePublisher
            .map { fee in
                let parameters = fee.value.value?.parameters as? SafeTransactionFeeParameters
                return parameters.map { !$0.isDeployed } ?? false
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$includesSetupFee)
    }
}
