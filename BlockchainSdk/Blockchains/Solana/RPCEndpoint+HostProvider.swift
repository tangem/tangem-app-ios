//
//  RPCEndpoint+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SolanaSwift

extension RPCEndpoint: HostProvider {
    var host: String {
        url.hostOrUnknown
    }
}
