//
//  NEARNetworkParams.ViewAccount.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkParams {
    struct ViewAccount: Encodable {
        enum RequestType: String, Encodable {
            case viewAccount = "view_account"
        }

        let requestType: RequestType
        let finality: Finality
        let accountId: String
    }
}
