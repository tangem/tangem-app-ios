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

    init(
        incomingActionHandler: IncomingActionHandler,
        externalLinkResponder: IncomingActionResponder,
        incomingActionParser: IncomingActionParser = IncomingActionParser()
    ) {
        self.incomingActionHandler = incomingActionHandler
        self.externalLinkResponder = externalLinkResponder
        self.incomingActionParser = incomingActionParser
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
    case incomingAction
    case browser

    init?(link: URL, incomingActionParser: IncomingActionParser) {
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
