//
//  SubscanAPIParams.ExtrinsicsList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension SubscanAPIParams {
    struct ExtrinsicsList: Encodable {
        enum Order: Encodable {
            case asc
            case desc
        }

        let address: String
        let order: Order
        let page: Int
        let row: Int
    }
}
