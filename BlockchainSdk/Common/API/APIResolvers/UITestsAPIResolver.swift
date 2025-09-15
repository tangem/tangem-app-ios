//
//  UITestsAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

#if DEBUG
struct UITestsAPIResolver {
    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .cardano = blockchain else {
            return nil
        }

        switch providerType {
        case .cardanoMock:
            return .init(url: URL(string: "https://wiremock.tests-d.com/cardano")!)
        default:
            return nil
        }
    }
}
#endif
