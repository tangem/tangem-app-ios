//
//  IncomingActionParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public class IncomingActionParser {
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService

    private var incomingActionURLParsers: [IncomingActionURLParser] = [
        NDEFURLParser(),
        DismissSafariActionURLHelper(),
        SellActionURLHelper(),
        WalletConnectURLParser(),
        BlockchainURLSchemesParser(isURLSchemeSupported: SupportedURLSchemeCheck.isURLSchemeSupported),
    ]

    public init() {}

    public func parseDeeplink(_ url: URL) -> IncomingAction? {
        guard validateURL(url) else { return nil }

        for parser in incomingActionURLParsers {
            if let action = parser.parse(url) {
                return action
            }
        }

        return nil
    }

    public func parseIntent(_ intent: String) -> IncomingAction? {
        switch intent {
        case AppIntent.scanCard.rawValue:
            return .start
        default:
            AppLog.shared.debug("Received unknown intent: \(intent)")
            return nil
        }
    }

    private func validateURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString

        if urlString.starts(with: IncomingActionConstants.tangemDomain)
            || urlString.starts(with: IncomingActionConstants.appTangemDomain)
            || SupportedURLSchemeCheck.isURLSchemeSupported(for: url) {
            return true
        }

        return false
    }
}

private extension IncomingActionParser {
    enum AppIntent: String {
        case scanCard = "ScanTangemCardIntent"
    }
}

private enum SupportedURLSchemeCheck {
    static func isURLSchemeSupported(for url: URL) -> Bool {
        if let supportedSchemes: [String] = InfoDictionaryUtils.bundleURLSchemes.value() {
            return supportedSchemes.contains(url.scheme ?? "")
        } else {
            return url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme)
        }
    }
}
