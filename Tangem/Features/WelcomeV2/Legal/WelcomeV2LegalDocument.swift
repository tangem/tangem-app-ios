//
//  WelcomeV2LegalDocument.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A legal document reachable from the welcome footer.
enum WelcomeV2LegalDocument {
    case termsOfService
    case privacyPolicy

    /// The footer carries plain links, so the tapped URL is what identifies the document.
    init(url: URL) {
        self = url == AppConstants.tosURL ? .termsOfService : .privacyPolicy
    }

    var url: URL {
        switch self {
        case .termsOfService: AppConstants.tosURL
        case .privacyPolicy: AppConstants.privacyPolicyURL
        }
    }

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .termsOfService: .welcomeV2DocumentTerms
        case .privacyPolicy: .welcomeV2DocumentPrivacy
        }
    }
}
