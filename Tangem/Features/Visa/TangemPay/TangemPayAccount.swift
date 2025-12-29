//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemVisa
import TangemSdk
import TangemFoundation
import TangemAssets
import TangemLocalization

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

    // MARK: - Withdraw

    let expressCEXTransactionProcessor: ExpressCEXTransactionProcessor
    let withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider

    // MARK: - Balances

    let mainHeaderBalanceProvider: MainHeaderBalanceProvider

    var balancesProvider: TangemPayBalancesProvider { balancesService }

    let customerInfoManagementService: any CustomerInfoManagementService
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
        customerInfoManagementService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        expressCEXTransactionProcessor: ExpressCEXTransactionProcessor,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider
    ) {
        customerInfoSubject = CurrentValueSubject((customerInfo, productInstance))
        self.customerInfoManagementService = customerInfoManagementService
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
        runTask { [self] in
            do throws(TangemPayAPIServiceError) {
                let customerInfo = try await customerInfoManagementService.loadCustomerInfo()

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
        let response = try await customerInfoManagementService.getPin(
            cardId: cardId,
            sessionId: sessionId
        )
        let decryptedBlock = try RainCryptoUtilities.decryptSecret(
            base64Secret: response.encryptedPin,
            base64Iv: response.iv,
            secretKey: secretKey
        )

        return try RainCryptoUtilities.decryptPinBlock(
            encryptedBlock: decryptedBlock
        )
    }

    func freeze() async throws {
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        switch response.status {
        case .completed, .canceled:
            await loadCustomerInfo()
        case .new, .processing:
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        }
    }

    func unfreeze() async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
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
}

private extension VisaCustomerInfoResponse {
    var cardIfActiveOrBlocked: VisaCustomerInfoResponse.Card? {
        [.active, .blocked].contains(productInstance?.status)
            ? card
            : nil
    }
}

private extension TangemPayAccount {
    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}
