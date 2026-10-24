//
//  IncomingActionParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

class IncomingActionParser {
    // MARK: - Properties

    private var incomingActionURLParsers: [IncomingActionURLParser] = [
        DismissSafariActionURLHelper(),
        SellActionURLHelper(),
        WalletConnectURLParser(),
        BlockchainURLSchemesParser(),
        OnrampIncomingActionURLParser(),
        TangemPayOnboardingLinkParser(),
        TangemPayCampaignLinkParser(),
        DeeplinkParser(),
        NdefLinkParser(),
    ]

    /// Kept out of the list above on purpose: it claims any page on our domain, so it must have the last word
    /// on a link. In the list it could be moved in front of a parser that owns a page, and that page would
    /// silently start opening in the browser instead.
    private let externalLinkParser = ExternalLinkParser()

    private let urlValidator: IncomingURLValidator

    // MARK: - Init

    init(urlValidator: IncomingURLValidator = CommonIncomingURLValidator()) {
        self.urlValidator = urlValidator
    }

    // MARK: - Public Implementation

    func parseIncomingURL(_ url: URL) -> IncomingAction? {
        // A scheme is case-insensitive, so iOS opens the app on `Tangem://` as readily as on `tangem://`, while
        // everything below reads a link as it is written. Normalised once here, so nowhere else has to.
        let url = url.withLowercasedScheme()

        guard urlValidator.validate(url) else {
            return nil
        }

        for parser in incomingActionURLParsers {
            if let action = try? parser.parse(url) {
                return action
            }
        }

        return externalLinkParser.parse(url)
    }

    /// Reads a push notification's payload: a payment push, a link carried under the `deeplink` or `link` key,
    /// or a transaction push, which is assembled into a token link.
    func parse(push userInfo: [AnyHashable: Any]) -> IncomingAction? {
        if let payload = TangemPayPushParser().parse(from: userInfo) {
            return .navigation(payload.action)
        }

        if let link = [PushKeys.deeplink, PushKeys.externalLink].compactMap({ userInfo[$0] as? String }).first {
            return URL(string: link).flatMap(parseIncomingURL)
        }

        if let payload = JointAccountPushPayload(userInfo: userInfo) {
            return .navigation(payload.action)
        }

        // A temporary crutch, while the push of deeplink transactions is not formed on the back, but is collected locally
        guard let payload = TransactionPushPayload(userInfo: userInfo) else {
            return nil
        }

        let url = TransactionPushActionURLHelper(
            type: payload.type.rawValue,
            networkId: payload.networkId,
            tokenId: payload.tokenId,
            userWalletId: payload.userWalletId,
            derivationPath: payload.derivationPath,
            transactionId: payload.transactionId,
            accountId: payload.accountId
        ).buildURL(scheme: .withoutRedirectUniversalLink)

        return parseIncomingURL(url)
    }

    func parseIntent(_ intent: String) -> IncomingAction? {
        switch intent {
        case AppIntent.scanCard.rawValue:
            return .start
        default:
            AppLogger.warning("Received unknown intent: \(intent)")
            return nil
        }
    }
}

private extension IncomingActionParser {
    enum AppIntent: String {
        case scanCard = "ScanTangemCardIntent"
    }

    /// The keys a push carries a link under.
    enum PushKeys {
        static let deeplink = "deeplink"
        static let externalLink = "link"
    }
}

private extension URL {
    /// The link as it would have been written in lower case. A link that already is one comes back untouched,
    /// so nothing that works today is rebuilt on its way in.
    func withLowercasedScheme() -> URL {
        guard let scheme, scheme != scheme.lowercased() else {
            return self
        }

        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme.lowercased()

        return components?.url ?? self
    }
}

enum SupportedURLSchemeCheck {
    static func isURLSchemeSupported(for url: URL) -> Bool {
        guard let supportedSchemes: [[String]] = InfoDictionaryUtils.bundleURLSchemes.value() else {
            // impossible case
            return false
        }
        return supportedSchemes.flatMap { $0 }.contains(url.scheme ?? "")
    }
}
