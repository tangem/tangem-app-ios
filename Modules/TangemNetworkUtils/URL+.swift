//
//  URL+.swift
//  TangemNetworkUtils
//
//  Created by Andrew Son on 27/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension URL {
    var hostOrUnknown: String {
        host ?? "Unknown Host"
    }
}
