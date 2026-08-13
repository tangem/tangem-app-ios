//
//  StubTangemPayCashbackDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay
@testable import Tangem

final class StubTangemPayCashbackDataProvider: TangemPayCashbackDataProviding {
    private let history: Result<TangemPayCashbackHistoryResponse, TangemPayAPIServiceError>
    private let promotions: Result<TangemPayCashbackPromotionsResponse, TangemPayAPIServiceError>
    private let accrualsDocs: Result<TangemPayCashbackAccrualsDocsResponse, TangemPayAPIServiceError>
    private let state = OSAllocatedUnfairLock(initialState: [Int]())

    var requestedMonths: [Int] {
        state.withLock { $0 }
    }

    init(
        history: Result<TangemPayCashbackHistoryResponse, TangemPayAPIServiceError>,
        promotions: Result<TangemPayCashbackPromotionsResponse, TangemPayAPIServiceError>,
        accrualsDocs: Result<TangemPayCashbackAccrualsDocsResponse, TangemPayAPIServiceError>
    ) {
        self.history = history
        self.promotions = promotions
        self.accrualsDocs = accrualsDocs
    }

    func getCashbackHistory(months: Int) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse {
        state.withLock { $0.append(months) }

        return try history.get()
    }

    func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse {
        try promotions.get()
    }

    func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse {
        try accrualsDocs.get()
    }
}
