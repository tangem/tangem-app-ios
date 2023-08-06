//
//  OrganizeTokensOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum OrganizeTokensOptions {
    enum Grouping {
        case none
        case byBlockchainNetwork
    }

    enum Sorting {
        case dragAndDrop
        case byBalance
    }
}
