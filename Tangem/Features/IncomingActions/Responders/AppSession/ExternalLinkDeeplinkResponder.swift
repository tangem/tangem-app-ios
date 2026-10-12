//
//  ExternalLinkDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Opens a page of ours in the in-app browser, from wherever the user is. Answers last, so any screen that
/// wants to do something else with the link gets it first.
final class ExternalLinkDeeplinkResponder {
    @Injected(\.safariManager) private var safariManager: SafariManager

    private var safariHandle: SafariHandle?
}

// MARK: - IncomingActionResponder

extension ExternalLinkDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .externalLink(let url) = action else {
            return false
        }

        // The same page arriving twice is answered by the browser already showing it.
        guard safariHandle?.isMatching(startingURL: url) != true else {
            return true
        }

        DeeplinkFloatingSheet.dismissActive()

        safariHandle = safariManager.openURL(
            url,
            configuration: .init(),
            onDismiss: { [weak self] in self?.safariHandle = nil },
            onSuccess: { [weak self] _ in self?.safariHandle = nil }
        )

        return true
    }
}
