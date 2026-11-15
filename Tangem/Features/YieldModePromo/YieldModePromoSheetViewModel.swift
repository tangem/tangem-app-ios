//
//  YieldModePromoSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemUI

@MainActor
final class YieldModePromoSheetViewModel: Identifiable {
    let data: YieldModePromoSheetData

    let tokenIcons: [TokenIconInfo] = ["usd-coin", "dai", "tether"].map {
        TokenIconInfo.remote(name: $0, imageURL: IconURLBuilder().tokenIconURL(id: $0))
    }

    private let analyticsLogger: YieldModePromoAnalyticsLogger
    private weak var routable: YieldModePromoSheetRoutable?
    private let appearanceSubject = PassthroughSubject<Void, Never>()
    private var isOutcomeHandled = false

    init(
        data: YieldModePromoSheetData,
        routable: YieldModePromoSheetRoutable?,
        analyticsLogger: YieldModePromoAnalyticsLogger = CommonYieldModePromoAnalyticsLogger()
    ) {
        self.data = data
        self.routable = routable
        self.analyticsLogger = analyticsLogger
    }

    var title: String {
        Localization.yieldModuleMainPromoTitle(PercentFormatter().format(data.apy, option: .interval))
    }

    var subtitle: String {
        Localization.yieldModuleMainPromoSubtitle
    }

    var tokensCountText: String {
        Localization.yieldModuleMainPromoTokensCount(data.tokensCount)
    }

    var actionTitle: String {
        Localization.yieldModuleMainPromoButton
    }

    var appearancePublisher: AnyPublisher<Void, Never> {
        appearanceSubject.eraseToAnyPublisher()
    }

    func onAppear() {
        appearanceSubject.send()
    }

    func close() {
        guard let routable, markOutcomeHandled() else {
            return
        }

        analyticsLogger.logClosed(data: data, method: .cross)
        routable.dismissYieldModePromo()
    }

    func tryYieldMode() {
        guard let routable, markOutcomeHandled() else {
            return
        }

        analyticsLogger.logTryYieldMode(data: data)
        routable.dismissYieldModePromo()
        routable.openYieldModeEarn()
    }

    func onDisappear() {
        guard markOutcomeHandled() else {
            return
        }

        analyticsLogger.logClosed(data: data, method: .swipe)
    }

    private func markOutcomeHandled() -> Bool {
        guard !isOutcomeHandled else {
            return false
        }

        isOutcomeHandled = true
        return true
    }
}
