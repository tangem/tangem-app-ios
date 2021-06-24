//
//  Constants.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

enum Constants {
    static var tangemDomain: String { tangemDomainUrl.absoluteString }
    static var tangemDomainUrl: URL { URL(string: "https://tangem.com")! }
    static var bitcoinTxStuckTimeSec: TimeInterval {
//        3600 * 24 * 1
        0 // for testing RBF
    }
}
