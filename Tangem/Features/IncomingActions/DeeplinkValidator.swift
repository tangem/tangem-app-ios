//
//  DeeplinkValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol DeeplinkValidator {
    func hasMinimumDataForHandling(deeplink: DeeplinkNavigationAction) -> Bool
}

struct CommonDeepLinkValidator {
    private func hasEnoughTokenChartParams(params: DeeplinkNavigationAction.Params) -> Bool {
        areParamsValid(params, keys: \.tokenId)
    }

    private func hasEnoughStakingParams(params: DeeplinkNavigationAction.Params) -> Bool {
        areParamsValid(params, keys: \.tokenId, \.networkId)
    }

    private func hasEnoughYieldParams(params: DeeplinkNavigationAction.Params) -> Bool {
        areParamsValid(params, keys: \.tokenId, \.networkId)
    }

    private func hasEnoughOnboardVisaParams(params: DeeplinkNavigationAction.Params) -> Bool {
        areParamsValid(params, keys: \.entry, \.id)
    }

    private func hasEnoughPayAppParams(params: DeeplinkNavigationAction.Params) -> Bool {
        areParamsValid(params, keys: \.id)
    }

    /// SurveySparrow tokens have no fixed format by contract — opaque vendor identifiers
    /// of arbitrary shape (e.g. `ntt-…`, `tt-…`, future base64-like values). We only
    /// check presence, not character set, to avoid rejecting valid tokens.
    private func hasEnoughSurveyParams(params: DeeplinkNavigationAction.Params) -> Bool {
        params.surveyToken?.nilIfEmpty != nil
    }

    /// Universal news-article link: `https://tangem.com/news/{category}/{id}-{slug}`.
    /// Numeric article id is mandatory — an article screen cannot be opened without it.
    private func hasEnoughNewsArticleParams(params: DeeplinkNavigationAction.Params) -> Bool {
        guard areParamsValid(params, keys: \.id), let id = params.id else {
            return false
        }

        return paramsHaveOnlyNumericCharacters([id])
    }

    private func hasValidNewsParams(params: DeeplinkNavigationAction.Params) -> Bool {
        let values = [params.categoryId, params.id].compactMap { $0 }

        return paramsHaveOnlyValidCharacters(values) && paramsHaveOnlyNumericCharacters(values)
    }

    private func hasEnoughTokenParams(params: DeeplinkNavigationAction.Params) -> Bool {
        guard areParamsValid(params, keys: \.tokenId, \.networkId) else {
            return false
        }

        switch params.type {
        case .some(let type) where type == .onrampStatusUpdate || type == .swapStatusUpdate:
            return params.derivationPath != nil && params.transactionId != nil

        case .some, .none:
            return true
        }
    }
}

// MARK: - Helpers

private extension CommonDeepLinkValidator {
    private func paramsHaveOnlyValidCharacters(_ params: [String]) -> Bool {
        params.allSatisfy { $0.range(of: Constants.regex, options: .regularExpression) != nil }
    }

    private func paramsHaveOnlyNumericCharacters(_ params: [String]) -> Bool {
        params.allSatisfy { $0.range(of: Constants.numericRegex, options: .regularExpression) != nil }
    }

    private func areParamsValid(_ params: DeeplinkNavigationAction.Params, keys: KeyPath<DeeplinkNavigationAction.Params, String?>...) -> Bool {
        let values = keys.compactMap { params[keyPath: $0] }

        guard values.count == keys.count else {
            return false
        }

        return paramsHaveOnlyValidCharacters(values)
    }
}

// MARK: - Constans

private extension CommonDeepLinkValidator {
    enum Constants {
        static let regex: String = "^[a-zA-Z0-9-_@\\.]+$"
        static let numericRegex: String = "^[0-9]+$"
    }
}

// MARK: - DeeplinkValidator

extension CommonDeepLinkValidator: DeeplinkValidator {
    func hasMinimumDataForHandling(deeplink: DeeplinkNavigationAction) -> Bool {
        let params = deeplink.params

        switch deeplink.destination {
        case .token:
            return hasEnoughTokenParams(params: params)

        case .staking:
            return hasEnoughStakingParams(params: params)

        case .yield:
            return hasEnoughYieldParams(params: params)

        case .tokenChart:
            return hasEnoughTokenChartParams(params: params)

        case .tokenExchanges:
            return hasEnoughTokenChartParams(params: params)

        case .buy, .link, .sell, .swap, .referral, .markets, .promo:
            return paramsHaveOnlyValidCharacters([params.tokenId, params.networkId, params.promoCode].compactMap { $0 })

        case .earn:
            return paramsHaveOnlyValidCharacters([params.earnType, params.networkId].compactMap { $0 })

        case .survey:
            return hasEnoughSurveyParams(params: params)

        case .onboardVisa:
            return hasEnoughOnboardVisaParams(params: params)

        case .payApp:
            return hasEnoughPayAppParams(params: params)

        case .news:
            return hasValidNewsParams(params: params)

        case .newsArticle:
            return hasEnoughNewsArticleParams(params: params)
        }
    }
}
