//
//  APIListProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol APIListProvider: Initializable {
    var apiList: APIList { get }
}

private struct APIListProviderKey: InjectionKey {
    static var currentValue: APIListProvider = CommonAPIListProvider()
}

extension InjectedValues {
    var apiListProvider: APIListProvider {
        get { Self[APIListProviderKey.self] }
        set { Self[APIListProviderKey.self] = newValue }
    }
}
