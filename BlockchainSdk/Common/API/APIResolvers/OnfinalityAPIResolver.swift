//
//  OnfinalityAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct OnfinalityAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve() -> NodeInfo? {
        guard let url = URL(string: "https://bittensor-finney.api.onfinality.io/rpc/") else {
            return nil
        }

        return .init(
            url: url,
            keyInfo: APIHeaderKeyInfo(
                headerName: Constants.onfinalityApiKeyHeaderName,
                headerValue: keysConfig.bittensorOnfinalityKey
            )
        )
    }
}
