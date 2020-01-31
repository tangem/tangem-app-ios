//
//  NetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class NetworkManager<ProviderType> where ProviderType: NetworkProvider {
    let providers:[ProviderType]
    
    init(providers: [ProviderType]) {
        self.providers = providers
    }
    
    
}


protocol NetworkProvider {
    var isTestnetSupported: Bool { get }
}
