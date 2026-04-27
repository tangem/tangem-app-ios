//
//  Address.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol Address {
    var value: String { get }
    var localizedName: String { get }
    var type: AddressType { get }
}
