//
//  OnfinalityAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnfinalityAPIResolver {
    let config: BlockchainSdkConfig

    func resolve() -> NodeInfo? {
        guard let url = URL(string: "https://bittensor-finney.api.onfinality.io/rpc/") else {
            return nil
        }

        return .init(
            url: url,
            keyInfo: APIHeaderKeyInfo(
                headerName: Constants.onfinalityApiKeyHeaderName,
                headerValue: config.bittensorOnfinalityKey
            )
        )
    }
}
