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
}

extension TangemBlogUrlBuilder {
    enum Post {
        case fee
        case scanCard
        case refundedDex
        case whatIsStaking
        case seedNotify
        case mobileVsHardware
        case giveRevokePermission
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
        case .mobileVsHardware:
            "mobile-vs-hardware"
        case .giveRevokePermission:
            "give-revoke-permission"
        }
    }
}
