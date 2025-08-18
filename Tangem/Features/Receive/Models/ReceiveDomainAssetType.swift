//
//  ReceiveDomainAssetType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum ReceiveAsset: Identifiable {
    case address(ReceiveAddressInfo)
    case domain(name: String, ReceiveAddressInfo)

    var id: String {
        switch self {
        case .address(let addressInfo):
            return addressInfo.id
        case .domain(let domainName, let addressInfo):
            return "\(domainName)_\(addressInfo.id)"
        }
    }
}
