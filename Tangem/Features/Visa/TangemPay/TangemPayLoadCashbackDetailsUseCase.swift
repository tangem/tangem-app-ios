//
//  TangemPayLoadCashbackDetailsUseCase.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

final class TangemPayLoadCashbackDetailsUseCase {
    private let provider: any TangemPayCashbackDataProviding
    private let referenceDate: Date

    init(
        provider: some TangemPayCashbackDataProviding,
        referenceDate: Date = .now
    ) {
        self.provider = provider
        self.referenceDate = referenceDate
    }

    func loadCashbackDetails(months: Int = 5) async throws -> TangemPayCashbackDetails {
        async let historyRequest = provider.getCashbackHistory(months: months)
        async let promotionsRequest = provider.getCashbackPromotions()
        async let accrualsDocsRequest = provider.getCashbackAccrualsDocs()

        let (history, promotions, accrualsDocs) = try await (historyRequest, promotionsRequest, accrualsDocsRequest)

        return TangemPayCashbackDetails(
            history: history,
            promotions: promotions,
            accrualsDocs: accrualsDocs,
            months: months,
            referenceDate: referenceDate
        )
    }
}
