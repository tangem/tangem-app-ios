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

    private let deeplinkValidator: DeeplinkValidator

    // MARK: - Init

    init(deeplinkValidator: DeeplinkValidator = CommonDeepLinkValidator()) {
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
            transactionId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.transactionId],
            promoCode: keyedQueryItems[IncomingActionConstants.DeeplinkParams.promoCode],
            entry: keyedQueryItems[IncomingActionConstants.DeeplinkParams.entry],
            id: keyedQueryItems[IncomingActionConstants.DeeplinkParams.id],
            categoryId: keyedQueryItems[IncomingActionConstants.DeeplinkParams.categoryId],
            refcode: keyedQueryItems[IncomingActionConstants.DeeplinkParams.refcode],
            campaign: keyedQueryItems[IncomingActionConstants.DeeplinkParams.campaign],
            order: keyedQueryItems[IncomingActionConstants.DeeplinkParams.order]?.lowercased(),
            interval: keyedQueryItems[IncomingActionConstants.DeeplinkParams.interval]?.lowercased(),
            earnType: keyedQueryItems[IncomingActionConstants.DeeplinkParams.earnType]?.lowercased(),
        )
    }

    private func destination(for host: String) -> IncomingActionConstants.DeeplinkDestination? {
        guard let destination = IncomingActionConstants.DeeplinkDestination(rawValue: host) else {
            return nil
        }
        // `.newsArticle` is a semantic destination emitted only by `NewsIncomingLinkParser`
        // for universal links. It must never be resolved from a `tangem://` host.
        guard destination != .newsArticle else {
            return nil
        }
        return destination
    }

    private func parseExternalLink(_ url: URL) -> IncomingAction? {
        if url.pathComponents.contains(IncomingActionConstants.ndefPath) {
            return .start
        }

        // First path component is '/'
        // The second one is the one we are looking for
        if url.pathComponents.count == 2, url.pathComponents.last == IncomingActionConstants.DeeplinkDestination.payApp.rawValue {
            let deeplinkNavAction = DeeplinkNavigationAction(
                destination: .payApp,
                params: getDeeplinkParams(from: url),
                deeplinkString: url.absoluteString
            )

            if deeplinkValidator.hasMinimumDataForHandling(deeplink: deeplinkNavAction) {
                return .navigation(deeplinkNavAction)
            } else {
                return nil
            }
        }

        let navAction = DeeplinkNavigationAction(
            destination: .link,
            params: .init(url: url),
            deeplinkString: url.absoluteString
        )
        return .navigation(navAction)
    }

    private func parseDeeplink(_ url: URL) -> IncomingAction? {
        guard let host = url.host,
              let destination = destination(for: host)
        else {
            return nil
        }

        let params = getDeeplinkParams(from: url)
        let deeplinkNavAction = DeeplinkNavigationAction(
            destination: destination,
            params: params,
            deeplinkString: url.absoluteString
        )

        guard deeplinkValidator.hasMinimumDataForHandling(deeplink: deeplinkNavAction) else {
            return nil
        }

        return .navigation(deeplinkNavAction)
    }
}

// MARK: - IncomingActionURLParser

extension DefaultIncomingLinkParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        if url.scheme == "https",
           let host = url.host,
           IncomingActionConstants.supportedExternalLinkHosts.contains(host.lowercased()) {
            return parseExternalLink(url)
        } else if url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme) {
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
