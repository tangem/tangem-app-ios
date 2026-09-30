//
//  EarnWidgetRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol EarnFeedWidgetRoutable: AnyObject {
    func openEarn()
    func openForYou()
}

final class EarnWidgetRouter: EarnFeedWidgetRoutable {
    private weak var navigation: (any FeedNavigation)?
    private let forYouRouter: any ForYouFeedRoutable

    init(navigation: any FeedNavigation, forYouRouter: any ForYouFeedRoutable) {
        self.navigation = navigation
        self.forYouRouter = forYouRouter
    }

    func openEarn() {
        navigation?.selectTab(.earn)
    }

    func openForYou() {
        forYouRouter.openForYou()
    }
}
