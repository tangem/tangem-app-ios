//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayAccount {
    var statusPublisher: AnyPublisher<VisaCustomerInfoResponse.ProductStatus, Never> {
        customerInfoSubject
            .map(\.productInstance.status)
            .eraseToAnyPublisher()
    }

    var card: VisaCustomerInfoResponse.Card? {
        customerInfoSubject.value.customerInfo.cardIfActiveOrBlocked
    }

    var cardPublisher: AnyPublisher<VisaCustomerInfoResponse.Card?, Never> {
        customerInfoSubject
            .map(\.customerInfo.cardIfActiveOrBlocked)
            .eraseToAnyPublisher()
    }

    var customerId: String {
        customerInfoSubject.value.customerInfo.id
    }

    // MARK: - Withdraw

    let expressCEXTransactionProcessor: ExpressCEXTransactionProcessor
    let withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider

    // MARK: - Balances

    let mainHeaderBalanceProvider: MainHeaderBalanceProvider
    var balancesProvider: TangemPayBalancesProvider { balancesService }

    let customerService: any CustomerInfoManagementService
    let withdrawTransactionService: any TangemPayWithdrawTransactionService

    private let orderStatusPollingService: TangemPayOrderStatusPollingService

    var depositAddress: String? {
        customerInfoSubject.value.customerInfo.depositAddress
    }

    var cardId: String {
        customerInfoSubject.value.productInstance.cardId
    }

    private let balancesService: any TangemPayBalancesService
    private let customerInfoSubject: CurrentValueSubject<(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance), Never>

    init(
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance,
        customerService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        expressCEXTransactionProcessor: ExpressCEXTransactionProcessor,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider
    ) {
        customerInfoSubject = CurrentValueSubject((customerInfo, productInstance))
        self.customerService = customerService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService
        self.expressCEXTransactionProcessor = expressCEXTransactionProcessor
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
        self.orderStatusPollingService = orderStatusPollingService
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
    }

    func loadBalance() async {
        await balancesService.loadBalance()
    }

    func loadCustomerInfo() async {
        do throws(TangemPayAPIServiceError) {
            let customerInfo = try await customerService.loadCustomerInfo()
            guard let productInstance = customerInfo.productInstance else {
                // [REDACTED_TODO_COMMENT]
                VisaLogger.info("Product instance was unexpectedly nil")
                return
            }

            customerInfoSubject.send((customerInfo, productInstance))

            if productInstance.status == .active {
                await loadBalance()
            }
        } catch {
            switch error {
            case .unauthorized:
                // [REDACTED_TODO_COMMENT]
                break
            case .moyaError, .apiError, .decodingError:
                // [REDACTED_TODO_COMMENT]
                break
            }
            VisaLogger.error("Failed to load customer info", error: error)
        }
    }

    func getPin() async throws -> String {
        let publicKey = try await RainCryptoUtilities
            .getRainRSAPublicKey(
                for: FeatureStorage.instance.visaAPIType
            )

        let (secretKey, sessionId) = try RainCryptoUtilities
            .generateSecretKeyAndSessionId(
                publicKey: publicKey
            )

        let response = try await customerService.getPin(sessionId: sessionId)
        let decryptedBlock = try RainCryptoUtilities.decryptSecret(
            base64Secret: response.secret,
            base64Iv: response.iv,
            secretKey: secretKey
        )

        return try RainCryptoUtilities.decryptPinBlock(
            encryptedBlock: decryptedBlock
        )
    }

    func freeze() async throws {
        let response = try await customerService.freeze(cardId: cardId)
        switch response.status {
        case .completed, .canceled:
            await loadCustomerInfo()
        case .new, .processing:
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        }
    }

    func unfreeze() async throws {
        let response = try await customerService.unfreeze(cardId: cardId)
        switch response.status {
        case .completed, .canceled:
            await loadCustomerInfo()
        case .new, .processing:
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        }
    }

    private func startFreezeUnfreezeOrderStatusPolling(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.freezeUnfreezeOrderPollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.loadCustomerInfo()
                }
            },
            onCanceled: {
                // [REDACTED_TODO_COMMENT]
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll order status", error: error)
            }
        )
    }

    private func setupBalance() async {
        await balancesService.loadBalance()
    }
}

private extension VisaCustomerInfoResponse {
    var cardIfActiveOrBlocked: VisaCustomerInfoResponse.Card? {
        [.active, .blocked].contains(productInstance?.status)
            ? card
            : nil
    }
}

// MARK: - TangemPayWithdrawTransactionServiceOutput

extension TangemPayAccount: TangemPayWithdrawTransactionServiceOutput {
    func withdrawTransactionDidSent() {
        Task {
            // Update balance after withdraw with some delay
            try await Task.sleep(for: .seconds(5))
            await setupBalance()
        }
    }
}

private extension TangemPayAccount {
    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}
