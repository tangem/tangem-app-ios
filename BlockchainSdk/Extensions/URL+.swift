//
//  URL+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension URL {
    var hostOrUnknown: String {
        host ?? "Unknown Host"
    }
}
