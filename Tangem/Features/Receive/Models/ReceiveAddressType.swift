//
//  ReceiveAddressType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ReceiveAddressType: Identifiable {
    case address(ReceiveAddressInfo)
    case domain(_ addressName: String, ReceiveAddressInfo)

    var id: String {
        switch self {
        case .address(let addressInfo):
            return addressInfo.id
        case .domain(let addressName, let addressInfo):
            return "\(addressName)_\(addressInfo.id)"
        }
    }
}
