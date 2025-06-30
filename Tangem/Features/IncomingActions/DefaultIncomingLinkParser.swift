//
//  DefaultIncomingLinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultIncomingLinkParser {
    // MARK: - Type Aliases

    typealias DeeplinkParams = DeeplinkNavigationAction.DeeplinkParams
    typealias DeeplinkKind = DeeplinkNavigationAction.DeeplinkParams.DeeplinkKind

    // MARK: - Properties

    private let isFeatureAvailable: Bool

    // MARK: - Init

    init(isFeatureAvailable: Bool) {
        self.isFeatureAvailable = isFeatureAvailable
    }

    // MARK: - Private Implementation

    private func getDeeplinkParams(from url: URL) -> DeeplinkParams {
        let keyedQueryItems = url.getKeyedQueryItems()
        return DeeplinkParams(
            kind: keyedQueryItems[Constants.typeParam].flatMap { DeeplinkKind(rawValue: $0) },
            name: keyedQueryItems[Constants.nameParam],
            tokenId: keyedQueryItems[Constants.tokenIdParam]?.lowercased(),
            networkId: keyedQueryItems[Constants.networkIdParam]?.lowercased(),
            userWalletId: keyedQueryItems[Constants.userWalletIdParam],
            derivationPath: keyedQueryItems[Constants.derivationPathParam],
            transactionId: keyedQueryItems[Constants.transactionIdParam]
        )
    }

    private func destination(for host: String) -> DeeplinkNavigationAction.DeeplinkDestination? {
        DeeplinkNavigationAction.DeeplinkDestination(rawValue: host)
    }

    private func parseExternalLink(_ url: URL) -> IncomingAction {
        let navAction = DeeplinkNavigationAction(destination: .link, params: .init(url: url))
        return .navigation(navAction)
    }

    private func parseDeeplink(_ url: URL) -> IncomingAction? {
        guard let host = url.host,
              let destination = destination(for: host)
        else {
            return nil
        }

        let params = getDeeplinkParams(from: url)
        let deeplinkNavAction = DeeplinkNavigationAction(destination: destination, params: params)

        guard deeplinkNavAction.hasMinimumDataForHandling() else {
            return nil
        }

        return .navigation(deeplinkNavAction)
    }
}

// MARK: - IncomingActionURLParser

extension DefaultIncomingLinkParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard isFeatureAvailable else {
            return nil
        }

        let urlString = url.absoluteString

        if urlString.starts(with: IncomingActionConstants.tangemDomain) || urlString.starts(with: IncomingActionConstants.appTangemDomain) {
            return parseExternalLink(url)
        } else if urlString.starts(with: IncomingActionConstants.universalLinkScheme) {
            return parseDeeplink(url)
        }

        return nil
    }
}

// MARK: - Constants

extension DefaultIncomingLinkParser {
    enum Constants {
        static let typeParam = "type"
        static let nameParam = "name"
        static let tokenIdParam = "token_id"
        static let networkIdParam = "network_id"
        static let userWalletIdParam = "user_wallet_id"
        static let derivationPathParam = "derivation_path"
        static let transactionIdParam = "transaction_id"

        enum Host: String, CaseIterable {
            case token
            case referral
            case buy
            case sell
            case markets
            case tokenChart = "token_chart"
            case staking
            case onramp
            case exchange
            case link
            case swap
        }
    }
}

// MARK: - Helpers

private extension URL {
    func getKeyedQueryItems() -> [String: String] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .keyedFirst(by: \.name)
            .compactMapValues { $0.value?.removingPercentEncoding } ?? [:]
    }
}
