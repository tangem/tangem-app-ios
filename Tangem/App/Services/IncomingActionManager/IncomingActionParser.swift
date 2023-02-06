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

    public init() {}

    public func handleDeeplink(_ url: URL) -> IncomingAction? {
        guard validateURL(url) else { return nil }

        if url.absoluteString.starts(with: Constants.ndefURL) {
            return .start
        }

        let parser = WalletConnectURLParser()
        if let uri = parser.parse(url) {
            return .walletConnect(uri)
        }

        return nil
    }

    public func handleIntent(_ intent: String) -> IncomingAction? {
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

        if urlString.starts(with: Constants.tangemDomain)
            || urlString.starts(with: Constants.appTangemDomain)
            || urlString.starts(with: Constants.universalLinkScheme) {
            return true
        }

        return false
    }
}

private extension IncomingActionParser {
    enum AppIntent: String {
        case scanCard = "ScanTangemCardIntent"
    }

    enum Constants {
        static var appTangemDomain = "https://app.tangem.com"
        static var universalLinkScheme = "tangem://"
        static var tangemDomain = AppConstants.tangemDomainUrl.absoluteString
        static var ndefURL = "\(appTangemDomain)/ndef"
    }
}
