//
//  ReceiveAddressInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import BlockchainSdk

struct ReceiveAddressInfo: Identifiable, Hashable {
    var id: String { type.rawValue }
    let address: String
    let type: AddressType
    /// Need to store in this struct to prevent recreating UIImage again and again in UI
    let addressQRImage: UIImage
}
