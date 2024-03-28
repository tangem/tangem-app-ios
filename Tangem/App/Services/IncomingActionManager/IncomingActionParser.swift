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
            || urlString.starts(with: IncomingActionConstants.universalLinkScheme) {
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
