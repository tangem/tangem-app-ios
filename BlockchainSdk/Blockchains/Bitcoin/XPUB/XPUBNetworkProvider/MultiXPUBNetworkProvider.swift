//
//  MultiXPUBNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Wrapper to support a switch between providers
class MultiXPUBNetworkProvider: MultiNetworkProvider, XPUBNetworkProvider {
    let blockchainName: String
    var providers: [any XPUBNetworkProvider]
    var currentProviderIndex: Int = 0

    init(providers: [any XPUBNetworkProvider], blockchainName: String) {
        self.providers = providers
        self.blockchainName = blockchainName
    }

    func getInfo(xpub: String) -> AnyPublisher<XPUBInfo, Error> {
        providerPublisher { $0.getInfo(xpub: xpub) }
    }
}
