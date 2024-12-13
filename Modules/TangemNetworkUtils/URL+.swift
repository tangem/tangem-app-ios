//
//  URL+.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension URL {
    var hostOrUnknown: String {
        host ?? "Unknown Host"
    }
}
