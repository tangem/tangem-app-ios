//
//  CustomerInfoManagementServiceStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay
@testable import Tangem

final class CustomerInfoManagementServiceStub: CustomerInfoManagementService {
    private let balanceResults: OSAllocatedUnfairLock<[Result<TangemPayBalance, TangemPayAPIServiceError>]>

    init(balanceResults: [Result<TangemPayBalance, TangemPayAPIServiceError>] = []) {
        self.balanceResults = OSAllocatedUnfairLock(initialState: balanceResults)
    }

    func getBalance() async throws(TangemPayAPIServiceError) -> TangemPayBalance {
        let result = balanceResults.withLock { results in
            results.isEmpty ? .failure(.unauthorized) : results.removeFirst()
        }

        return try result.get()
    }

    func loadCustomerInfo() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse {
        throw .unauthorized
    }

    func loadCustomerSummary() async throws(TangemPayAPIServiceError) -> TangemPayCustomerSummaryResponse {
        throw .unauthorized
    }

    func loadKYCAccessToken() async throws(TangemPayAPIServiceError) -> VisaKYCAccessTokenResponse {
        throw .unauthorized
    }

    func checkEligibility(product: TangemPayProduct) async throws(TangemPayAPIServiceError) -> TangemPayEligibilityCheckResponse {
        throw .unauthorized
    }

    func getCardDetails(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardDetailsResponse {
        throw .unauthorized
    }

    func getCardProcessorDetails(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayCardProcessorDetailsResponse {
        throw .unauthorized
    }

    func closeCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayCloseCardResponse {
        throw .unauthorized
    }

    func getPin(cardId: String, sessionId: String) async throws(TangemPayAPIServiceError) -> TangemPayGetPinResponse {
        throw .unauthorized
    }

    func setPin(cardId: String, pin: String, sessionId: String, iv: String) async throws(TangemPayAPIServiceError) -> TangemPaySetPinResponse {
        throw .unauthorized
    }

    func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        throw .unauthorized
    }

    func sendBankOfframpSignature(
        orderId: String,
        signature: String,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) {
        throw .unauthorized
    }

    func updateCardDisplayName(cardId: String, _ displayName: String) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        throw .unauthorized
    }

    func setCardLimit(cardId: String, amount: Int) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.ProductInstance {
        throw .unauthorized
    }

    func freeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        throw .unauthorized
    }

    func unfreeze(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayFreezeUnfreezeResponse {
        throw .unauthorized
    }

    func getTransactionHistory(limit: Int, cursor: String?) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse {
        throw .unauthorized
    }

    func getTransaction(transactionId: String) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse.Transaction {
        throw .unauthorized
    }

    func getWithdrawPreSignatureInfo(
        request: TangemPayWithdrawRequest
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawPreSignature {
        throw .unauthorized
    }

    func sendWithdrawTransaction(
        request: TangemPayWithdrawRequest,
        signature: TangemPayWithdrawSignature
    ) async throws(TangemPayAPIServiceError) -> TangemPayWithdrawTransactionResult {
        throw .unauthorized
    }

    func getOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        throw .unauthorized
    }

    func cancelOrder(orderId: String) async throws(TangemPayAPIServiceError) -> TangemPayCancelOrderResponse {
        throw .unauthorized
    }

    func findOrders(
        types: [String],
        statuses: [TangemPayOrderResponse.Status]
    ) async throws(TangemPayAPIServiceError) -> [TangemPayOrderResponse] {
        throw .unauthorized
    }

    func getCustomerOffers(deeplinkValue: String?) async throws(TangemPayAPIServiceError) -> TangemPayCustomerOffersResponse {
        throw .unauthorized
    }

    func getProductInstanceOffers(
        productInstanceId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayCustomerOffersResponse {
        throw .unauthorized
    }

    func getTariffPlanTransitions() async throws(TangemPayAPIServiceError) -> TangemPayTariffPlanTransitionsResponse {
        throw .unauthorized
    }

    func requestTariffPlanPendingTransition(
        pendingTariffPlanId: String
    ) async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan {
        throw .unauthorized
    }

    func cancelTariffPlanPendingTransition() async throws(TangemPayAPIServiceError) -> VisaCustomerInfoResponse.CustomerTariffPlan {
        throw .unauthorized
    }

    func getFee(type: TangemPayFeeType) async throws(TangemPayAPIServiceError) -> TangemPayFeeResponse {
        throw .unauthorized
    }

    func getFees(groups: [TangemPayFeeGroup]) async throws(TangemPayAPIServiceError) -> [TangemPayFeeResponse] {
        throw .unauthorized
    }

    func reissueCard(cardId: String) async throws(TangemPayAPIServiceError) -> TangemPayReissueCardResponse {
        throw .unauthorized
    }

    func getBankCredentials(productInstanceId: String) async throws(TangemPayAPIServiceError) -> TangemPayBankCredentialsResponse {
        throw .unauthorized
    }

    func getBankAccounts() async throws(TangemPayAPIServiceError) -> [TangemPayBankAccountResponse] {
        throw .unauthorized
    }

    func getBankOfframpOptions() async throws(TangemPayAPIServiceError) -> TangemPayBankOfframpOptionsResponse {
        throw .unauthorized
    }

    func loadEligibility() async throws(TangemPayAPIServiceError) -> TangemPayAvailabilityResponse {
        throw .unauthorized
    }

    func getCashbackSummary() async throws(TangemPayAPIServiceError) -> TangemPayCashbackSummaryResponse {
        throw .unauthorized
    }

    func getCashbackHistory(months: Int?) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse {
        throw .unauthorized
    }

    func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse {
        throw .unauthorized
    }

    func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse {
        throw .unauthorized
    }

    func getCashbackTransactionDetails(
        transactionId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayCashbackTransactionDetailsResponse {
        throw .unauthorized
    }

    func cancelKYC() async throws(TangemPayAPIServiceError) -> TangemPayCancelKYCResponse {
        throw .unauthorized
    }
}
