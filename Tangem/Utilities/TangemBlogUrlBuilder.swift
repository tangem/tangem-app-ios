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
        return URL(string: "https://tangem.com/\(Locale.webLanguageCode())/blog/post/\(post.path)/")!
    }

    func url(root: Root) -> URL {
        return URL(string: "https://tangem.com/\(Locale.webLanguageCode())/\(root.path)/")!
    }
}

extension TangemBlogUrlBuilder {
    enum Post {
        case fee
        case scanCard
        case refundedDex
        case whatIsStaking
        case seedNotify
    }

    enum Root {
        case pricing
    }
}

private extension TangemBlogUrlBuilder.Post {
    var path: String {
        switch self {
        case .fee:
            "what-is-a-transaction-fee-and-why-do-we-need-it"
        case .scanCard:
            "scan-tangem-card"
        case .refundedDex:
            "an-overview-of-cross-chain-bridges"
        case .whatIsStaking:
            "how-to-stake-cryptocurrency"
        case .seedNotify:
            "seed-notify"
        }
    }
}

private extension TangemBlogUrlBuilder.Root {
    var path: String {
        switch self {
        case .pricing:
            "pricing"
        }
    }
}
