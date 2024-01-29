//
//  IncomingActionURLHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol IncomingActionURLBuilder {
    func buildURL() -> URL
}

public protocol IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction?
}

public protocol IncomingActionURLHelper: IncomingActionURLBuilder & IncomingActionURLParser {
    var actionValue: String { get }
}

extension IncomingActionURLHelper {
    func buildURL() -> URL {
        var urlComponents = URLComponents(string: IncomingActionConstants.redirectBaseURL)!
        urlComponents.percentEncodedQueryItems = [.init(name: IncomingActionConstants.incoimingActionName, value: actionValue)]
        return urlComponents.url!
    }
}

// MARK: - Implementations

struct DismissSafariURLService: IncomingActionURLHelper {
    let actionValue: String = "dismissSafariVC"

    func parse(_ url: URL) -> IncomingAction? {
        guard url == buildURL() else {
            return nil
        }

        return .dismissSafariVC
    }
}
