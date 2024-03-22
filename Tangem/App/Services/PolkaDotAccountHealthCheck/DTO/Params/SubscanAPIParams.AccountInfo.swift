//
//  SubscanAPIParams.AccountInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIParams {
    struct AccountInfo: Encodable {
        /// The address of the account.
        let key: String
    }
}
