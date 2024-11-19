//
//  IncomingActionURLHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol IncomingActionURLBuilder {
    func buildURL(scheme: IncomingActionScheme) -> URL
}

public protocol IncomingActionURLParser {
    func parse(_ url: URL) throws -> IncomingAction?
}

public protocol IncomingActionURLHelper: IncomingActionURLBuilder & IncomingActionURLParser {}

public enum IncomingActionScheme: CaseIterable {
    case redirectLink
    case universalLink

    var baseScheme: String {
        switch self {
        case .redirectLink:
            return IncomingActionConstants.externalRedirectURL
        case .universalLink:
            return IncomingActionConstants.universalLinkRedirectURL
        }
    }
}
