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
        var urlComponents = URLComponents(string: "https://tangem.com/embed/blog/post/\(post.path)/")!
        urlComponents.queryItems = TangemUrlHelper.queryItems(utmCampaign: .articles)
        return urlComponents.url!
    }
}

extension TangemBlogUrlBuilder {
    enum Post {
        case fee
        case scanCard
        case refundedDex
        case whatIsStaking
        case mobileWallet
        case giveRevokePermission
        case seedPhraseFaq
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
        case .mobileWallet:
            "mobile-wallet"
        case .giveRevokePermission:
            "give-revoke-permission"
        case .seedPhraseFaq:
            "seed-phrase-faq"
        }
    }
}
