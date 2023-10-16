//
//  ManageTokensRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensRoutable: AnyObject {
    func openTokenSelector(coinId: String, with tokenItems: [TokenItem])
}
