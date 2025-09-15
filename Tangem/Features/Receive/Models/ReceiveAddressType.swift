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
            return "\(Constants.addressPrefix)_\(addressInfo.id)"
        case .domain(let addressName, let addressInfo):
            return "\(Constants.domainPrefix)_\(addressName)_\(addressInfo.id)"
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
}

// MARK: - Constants

extension ReceiveAddressType {
    enum Constants {
        static let addressPrefix = "address"
        static let domainPrefix = "domain"
    }
}
