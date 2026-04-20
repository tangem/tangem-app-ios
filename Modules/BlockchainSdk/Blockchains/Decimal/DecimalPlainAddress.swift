//
//  DecimalPlainAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalPlainAddress: Address {
    let value: String
    let type: AddressType

    var localizedName: String {
        switch type {
        case .default:
            return Constants.mainLocalizedName
        case .used(let type, _):
            return type.defaultLocalizedName
        case .legacy:
            return Constants.dscLocalizedName
        }
    }

    init(value: String, type: AddressType) {
        self.value = value
        self.type = type
    }
}

extension DecimalPlainAddress {
    enum Constants {
        static let mainLocalizedName = "Main"
        static let dscLocalizedName = "DSC"
    }
}
