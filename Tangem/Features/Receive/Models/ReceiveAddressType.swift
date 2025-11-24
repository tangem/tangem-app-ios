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
            return "\(key.id)_\(addressInfo.id)"
        case .domain(let addressName, let addressInfo):
            return "\(key.id)_\(addressName)_\(addressInfo.id)"
        }
    }

    var info: ReceiveAddressInfo {
        switch self {
        case .address(let info):
            return info
        case .domain(_, let info):
            return info
        }
    }

    var key: Key {
        switch self {
        case .address:
            return .address
        case .domain:
            return .domain
        }
    }

    var domainName: String? {
        switch self {
        case .address:
            return nil
        case .domain(let name, _):
            return name
        }
    }
}

extension ReceiveAddressType {
    enum Key: String, Identifiable, Hashable {
        var id: String {
            rawValue
        }

        case domain
        case address
    }
}
