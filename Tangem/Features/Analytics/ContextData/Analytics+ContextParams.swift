//
//  Analytics+ContextParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

extension Analytics {
    enum ContextParams {
        case userWallet(UserWalletId)
        case custom(AnalyticsContextData)
        case `default`
        case empty

        var analyticsParams: [Analytics.ParameterKey: String] {
            switch self {
            case .custom(let contextData):
                return contextData.analyticsParams
            case .userWallet(let userWalletId):
                let builder = AnalyticsDefaultContextParamsBuilder()
                let contextData = builder.getAnalyticsContextData(userWalletId: userWalletId)
                return contextData?.analyticsParams ?? [:]
            case .default:
                let builder = AnalyticsDefaultContextParamsBuilder()
                let contextData = builder.getDefaultAnalyticsContextData()
                return contextData?.analyticsParams ?? [:]
            case .empty:
                return [:]
            }
        }
    }
}

// MARK: - AnalyticsDefaultContextParamsBuilder

private class AnalyticsDefaultContextParamsBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func getDefaultAnalyticsContextData() -> AnalyticsContextData? {
        return userWalletRepository.selectedModel?.analyticsContextData
    }

    func getAnalyticsContextData(userWalletId: UserWalletId) -> AnalyticsContextData? {
        return userWalletRepository.models[userWalletId]?.analyticsContextData
    }
}
