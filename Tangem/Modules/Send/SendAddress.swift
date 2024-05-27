//
//  SendAddress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAddress: Equatable {
    let value: String?
    let source: Analytics.DestinationAddressSource
}
