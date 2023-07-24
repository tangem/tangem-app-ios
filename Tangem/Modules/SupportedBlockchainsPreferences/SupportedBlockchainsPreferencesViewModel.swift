//
//  SupportedBlockchainsPreferencesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class SupportedBlockchainsPreferencesViewModel: ObservableObject {
    @Published var blockchainViewModels: [DefaultToggleRowViewModel] = []

    init() {
        blockchainViewModels = Blockchain.allMainnetCases
            .map { blockchain -> (blockchain: Blockchain, supportedByDefault: Bool) in

                let supportedByDefault = SupportedBlockchains()
                    .mainnetBlockchains(for: .v1)
                    .contains(where: { $0.id == blockchain.id })

                return (blockchain: blockchain, supportedByDefault: supportedByDefault)
            }
            .sorted(by: { lhs, rhs in
                switch (lhs.supportedByDefault, rhs.supportedByDefault) {
                case (true, true), (false, false):
                    return lhs.blockchain.displayName < rhs.blockchain.displayName
                case (false, true):
                    return true
                case (true, false):
                    return false
                }
            })
            .map { blockchain, supportedByDefault in
                DefaultToggleRowViewModel(
                    title: blockchain.displayName,
                    // Disable the ability to hide an already working blockchain
                    isDisabled: supportedByDefault,
                    isOn: .init(get: {
                        let isEnabledManually = FeatureStorage().supportedBlockchainsIds.contains(blockchain.id)
                        return supportedByDefault || isEnabledManually
                    }, set: { newValue in
                        if newValue {
                            FeatureStorage().supportedBlockchainsIds.append(blockchain.id)
                        } else {
                            FeatureStorage().supportedBlockchainsIds.removeAll(where: { $0 == blockchain.id })
                        }
                    })
                )
            }
    }
}
