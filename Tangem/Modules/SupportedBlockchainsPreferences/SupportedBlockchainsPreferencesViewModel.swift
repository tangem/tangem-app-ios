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
            .sorted(by: \.displayName)
            .map { blockchain in
                DefaultToggleRowViewModel(
                    title: blockchain.displayName,
                    isDisabled: SupportedBlockchains().mainnetBlockchains(for: .v1).contains(where: { $0.id == blockchain.id }),
                    isOn: .init(get: {
                        FeatureStorage().supportedBlockchainsIds.contains(blockchain.id)
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
