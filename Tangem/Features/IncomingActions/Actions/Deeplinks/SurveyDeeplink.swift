//
//  SurveyDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// `tangem://survey?token`
struct SurveyDeeplink: HostNamedDeeplink, Equatable {
    static let host = "survey"

    let token: String

    var action: DeeplinkNavigationAction { .survey(self) }
}

// MARK: - Parsing

extension SurveyDeeplink {
    private enum Keys {
        static let token = "token"
    }

    init(link: DeeplinkURL) throws {
        // SurveySparrow tokens are opaque vendor identifiers of no fixed shape, so anything but emptiness
        // is accepted.
        guard let token = link.query.unchecked(Keys.token)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw DeeplinkQuery.ValidationError.missingValue(key: Keys.token)
        }

        self.token = token
    }
}
