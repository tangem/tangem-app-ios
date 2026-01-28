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

public class IncomingActionParser {
    // MARK: - Properties

    private var incomingActionURLParsers: [IncomingActionURLParser] = [
        DismissSafariActionURLHelper(),
        SellActionURLHelper(),
        WalletConnectURLParser(),
        BlockchainURLSchemesParser(),
        OnrampIncomingActionURLParser(),
        NewsIncomingLinkParser(),
        DefaultIncomingLinkParser(),
    ]

    private let urlValidator: IncomingURLValidator

    // MARK: - Init

    public init(urlValidator: IncomingURLValidator = CommonIncomingURLValidator()) {
        self.urlValidator = urlValidator
    }

    // MARK: - Public Implementation

    public func parseIncomingURL(_ url: URL) -> IncomingAction? {
        guard urlValidator.validate(url) else {
            return nil
        }

        for parser in incomingActionURLParsers {
            if let action = try? parser.parse(url) {
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
            AppLogger.warning("Received unknown intent: \(intent)")
            return nil
        }
    }
}

private extension IncomingActionParser {
    enum AppIntent: String {
        case scanCard = "ScanTangemCardIntent"
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
