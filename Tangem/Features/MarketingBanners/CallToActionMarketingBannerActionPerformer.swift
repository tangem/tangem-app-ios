//
//  CallToActionMarketingBannerActionPerformer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CallToActionMarketingBannerActionPerformer {
    private let incomingActionHandler: IncomingActionHandler
    private let externalLinkResponder: IncomingActionResponder
    private let incomingActionParser: IncomingActionParser
    private let openConciergeWaitlist: () -> Void

    init(
        incomingActionHandler: IncomingActionHandler,
        externalLinkResponder: IncomingActionResponder,
        incomingActionParser: IncomingActionParser = IncomingActionParser(),
        openConciergeWaitlist: @escaping () -> Void
    ) {
        self.incomingActionHandler = incomingActionHandler
        self.externalLinkResponder = externalLinkResponder
        self.incomingActionParser = incomingActionParser
        self.openConciergeWaitlist = openConciergeWaitlist
    }

    func perform(_ action: CallToActionMarketingBannerAction) {
        switch action {
        case .open(let link):
            open(link)
        case .dismiss(let campaignId):
            HiddenMarketingCampaignsStorage.hide(campaignId: campaignId)
        }
    }
}

// MARK: - Private

private extension CallToActionMarketingBannerActionPerformer {
    func open(_ link: URL) {
        switch CallToActionMarketingBannerLinkRoute(link: link, incomingActionParser: incomingActionParser) {
        case .conciergeWaitlist:
            openConciergeWaitlist()
        case .incomingAction:
            incomingActionHandler.handleIncomingURL(link)
        case .browser:
            _ = externalLinkResponder.didReceiveIncomingAction(.externalLink(link))
        case .none:
            break
        }
    }
}

// MARK: - Link route

enum CallToActionMarketingBannerLinkRoute: Equatable {
    case conciergeWaitlist
    case incomingAction
    case browser

    init?(link: URL, incomingActionParser: IncomingActionParser) {
        if ConciergeWaitlistLink.matches(link) {
            self = .conciergeWaitlist
            return
        }

        switch incomingActionParser.parseIncomingURL(link) {
        case .walletConnect, .externalLink, .navigation:
            self = .incomingAction
        case .dismissSafari, .start:
            return nil
        case .none:
            guard link.isHTTPS else {
                return nil
            }

            self = .browser
        }
    }
}
