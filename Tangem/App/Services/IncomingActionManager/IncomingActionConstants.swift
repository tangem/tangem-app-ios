//
//  IncomingActionConstants.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum IncomingActionConstants {
    static let appTangemDomain = "https://app.tangem.com"
    static let tangemDomain = "https://tangem.com"
    static let universalLinkScheme = "tangem://"
    static let ndefURL = "\(appTangemDomain)/ndef"
    static let externalRedirectURL = "\(tangemDomain)/redirect"
    static let universalLinkRedirectURL = "\(universalLinkScheme)redirect"
    static let incoimingActionName = "action"
}
