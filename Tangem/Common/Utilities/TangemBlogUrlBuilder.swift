//
//  TangemBlogUrlBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TangemBlogUrlBuilder {
    func url(post: Post) -> URL {
        let currentLanguageCode = Locale.current.languageCode ?? LanguageCode.ru

        let languageCode: String
        switch currentLanguageCode {
        case LanguageCode.ru:
            languageCode = currentLanguageCode
        default:
            languageCode = LanguageCode.en
        }
        return URL(string: "https://tangem.com/\(languageCode)/blog/post/\(post.path)/")!
    }
}

extension TangemBlogUrlBuilder {
    enum Post {
        case fee
    }
}

private extension TangemBlogUrlBuilder.Post {
    var path: String {
        switch self {
        case .fee:
            "what-is-a-transaction-fee-and-why-do-we-need-it"
        }
    }
}
