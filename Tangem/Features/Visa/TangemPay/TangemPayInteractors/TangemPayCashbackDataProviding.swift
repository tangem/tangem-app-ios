//
//  TangemPayCashbackDataProviding.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayCashbackDataProviding {
    func getCashbackHistory(months: Int) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse
    func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse
    func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse
}
