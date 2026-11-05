//
//  MobileSocialLoginUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MobileSocialLoginUrlBuilder {
    func learnMoreURL() -> URL? {
        URL(string: Self.learnMoreArticleURL)
    }
}

// MARK: - Constants

private extension MobileSocialLoginUrlBuilder {
    static let learnMoreArticleURL = "https://tangem.com/blog/post/cloud-login"
}
