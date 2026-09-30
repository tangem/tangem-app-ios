//
//  TangemPayFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayFeedRoutable: AnyObject {
    func openTangemPay(_ entry: FeedTangemPayEntry)
}

final class TangemPayFeedRouter: TangemPayFeedRoutable {
    private weak var host: (any FeedHostRoutable)?

    init(host: any FeedHostRoutable) {
        self.host = host
    }

    func openTangemPay(_ entry: FeedTangemPayEntry) {
        host?.openTangemPay(entry: entry)
    }
}
