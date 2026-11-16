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
        guard let rawToken = link.query.unchecked(Keys.token)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw DeeplinkQuery.ValidationError.missingValue(key: Keys.token)
        }

        guard let token = DeeplinkRules.surveyToken(rawToken) else {
            throw DeeplinkQuery.ValidationError.malformedValue(key: Keys.token)
        }

        self.token = token
    }
}
