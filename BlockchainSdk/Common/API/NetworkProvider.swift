//
//  NetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class NetworkProvider<Target: TargetType>: MoyaProvider<Target> {
    init(configuration: NetworkProviderConfiguration = NetworkProviderConfiguration()) {
        let session = Session(configuration: configuration.urlSessionConfiguration)

        super.init(session: session, plugins: configuration.plugins)
    }
}
