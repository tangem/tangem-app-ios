//
//  NEARNetworkParams.ProtocolConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkParams {
    struct ProtocolConfig: Encodable {
        let finality: Finality
    }
}
