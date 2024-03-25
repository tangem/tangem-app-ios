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
        enum Order: String, Encodable {
            case asc
            case desc
        }

        let address: String
        let order: Order
        let afterId: Int
        let page: Int
        let row: Int
    }
}
