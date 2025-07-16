//
//  DefaultIncomingLinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct DefaultIncomingLinkParser {
    // MARK: - Type Aliases

    typealias DeeplinkParams = DeeplinkNavigationAction.Params
    typealias DeeplinkType = IncomingActionConstants.DeeplinkType

    // MARK: - Properties

    private let isFeatureAvailable: Bool
    private let deeplinkValidator: DeeplinkValidator

    // MARK: - Init

    init(isFeatureAvailable: Bool, deeplinkValidator: DeeplinkValidator = CommonDeepLinkValidator()) {
        self.isFeatureAvailable = isFeatureAvailable
        self.deeplinkValidator = deeplinkValidator
    }

    // MARK: - Private Implementation

    private func getDeeplinkParams(from url: URL) -> DeeplinkParams {
        let keyedQueryItems = url.getKeyedQueryItems()
        return DeeplinkParams(
            type: keyedQueryItems[IncomingActionConstants.DeeplinkParams.type].flatMap { IncomingActionConstants.DeeplinkType(rawValue: $0) },
            name: keyedQueryItems[IncomingActionConstants.DeeplinkParams.name],
            tokenId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.tokenId]?.lowercased(),
            networkId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.networkId]?.lowercased(),
            userWalletId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.userWalletId],
            derivationPath: keyedQueryItems[IncomingActionConstants.DeeplinkParams.derivationPath],
            transactionId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.transactionId]
        )
    }

    private func destination(for host: String) -> IncomingActionConstants.DeeplinkDestination? {
        IncomingActionConstants.DeeplinkDestination(rawValue: host)
    }

    private func parseExternalLink(_ url: URL) -> IncomingAction {
        if url.pathComponents.contains(IncomingActionConstants.ndefPath) {
            return .start
        }

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

        guard deeplinkValidator.hasMinimumDataForHandling(deeplink: deeplinkNavAction) else {
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

// MARK: - Helpers

private extension URL {
    func getKeyedQueryItems() -> [String: String] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.value?.isNotEmpty ?? false }
            .keyedFirst(by: \.name)
            .compactMapValues { $0.value?.removingPercentEncoding } ?? [:]
    }
}
