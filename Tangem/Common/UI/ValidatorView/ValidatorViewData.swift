//
//  ValidatorViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ValidatorViewData: Hashable, Identifiable {
    let id: String
    let name: String
    let imageURL: URL?
    let aprFormatted: String?
    let detailsType: DetailsType?

    enum DetailsType: Hashable {
        case checkmark
        case chevron
        case balance(crypto: String, fiat: String)
    }
}
