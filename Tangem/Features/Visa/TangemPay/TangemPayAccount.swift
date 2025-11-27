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
    var tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never> {
        customerInfoSubject
            .compactMap(\.self?.tangemPayStatus)
            .eraseToAnyPublisher()
    }

    var tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never> {
        orderIdStorage.cardIssuingOrderIdPublisher
            .map { $0 != nil }
            .merge(with: didTapIssueOrderSubject.mapToValue(true))
            .eraseToAnyPublisher()
    }

    var tangemPayCard: VisaCustomerInfoResponse.Card? {
        mapToCard(visaCustomerInfoResponse: customerInfoSubject.value)
    }

    var tangemPayCardPublisher: AnyPublisher<VisaCustomerInfoResponse.Card?, Never> {
        customerInfoSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToCard(visaCustomerInfoResponse: $1) }
            .eraseToAnyPublisher()
    }

    lazy var tangemPayNotificationManager: TangemPayNotificationManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher
    )

    lazy var tangemPayIssuingManager: TangemPayIssuingManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher,
        tangemPayCardIssuingPublisher: tangemPayCardIssuingInProgressPublisher
    )

    // MARK: - Balances

    lazy var tangemPayTokenBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        walletModelId: .init(tokenItem: TangemPayUtilities.usdcTokenItem),
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    lazy var tangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
        tangemPayTokenBalanceProvider: tangemPayTokenBalanceProvider
    )

    lazy var tangemPayMainHeaderSubtitleProvider: MainHeaderSubtitleProvider = TangemPayMainHeaderSubtitleProvider(
        balanceSubject: balanceSubject
    )

    let customerInfoManagementService: any CustomerInfoManagementService

    var depositAddress: String? {
        customerInfoSubject.value?.depositAddress
    }

    var cardId: String? {
        customerInfoSubject.value?.productInstance?.cardId
    }

    var cardNumberEnd: String? {
        customerInfoSubject.value?.card?.cardNumberEnd
    }

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    private let authorizationTokensHandler: TangemPayAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer
    private let walletAddress: String
    private let tokenBalancesRepository: TokenBalancesRepository
    private let orderIdStorage: TangemPayOrderIdStorage

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>(.loading)

    private let didTapIssueOrderSubject = PassthroughSubject<Void, Never>()
    private var orderStatusPollingTask: Task<Void, Never>?

    init(
        authorizer: TangemPayAuthorizer,
        walletAddress: String,
        tokens: TangemPayAuthorizationTokens,
        tokenBalancesRepository: TokenBalancesRepository,
    ) {
        self.authorizer = authorizer
        self.walletAddress = walletAddress
        self.tokenBalancesRepository = tokenBalancesRepository

        authorizationTokensHandler = TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: authorizer.customerWalletId,
                authorizationService: authorizer.authorizationService
            )

        customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(
                authorizationTokensHandler: authorizationTokensHandler,
                authorizeWithCustomerWallet: authorizer.authorizeWithCustomerWallet
            )

        orderIdStorage = TangemPayOrderIdStorage(
            customerWalletAddress: walletAddress,
            appSettings: .shared
        )

        // No reference cycle here, self is stored as weak in all three entities
        tangemPayNotificationManager.setupManager(with: self)
        authorizationTokensHandler.authorizationTokensSaver = self
        tangemPayIssuingManager.setupDelegate(self)

        do {
            try authorizationTokensHandler.saveTokens(tokens: tokens)
        } catch {
            VisaLogger.error("Failed to save authorization tokens", error: error)
        }

        loadCustomerInfo()

        if let cardIssuingOrderId = orderIdStorage.cardIssuingOrderId {
            startOrderStatusPolling(orderId: cardIssuingOrderId, interval: Constants.cardIssuingOrderPollInterval)
        }
    }

    convenience init?(userWalletModel: UserWalletModel) {
        guard let (walletAddress, tokens) = TangemPayUtilities.getWalletAddressAndAuthorizationTokens(
            customerWalletId: userWalletModel.userWalletId.stringValue,
            keysRepository: userWalletModel.keysRepository
        ) else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(
            customerWalletId: userWalletModel.userWalletId.stringValue,
            interactor: userWalletModel.tangemPayAuthorizingInteractor,
            keysRepository: userWalletModel.keysRepository
        )

        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletModel.userWalletId)

        self.init(
            authorizer: authorizer,
            walletAddress: walletAddress,
            tokens: tokens,
            tokenBalancesRepository: tokenBalancesRepository
        )
    }

    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
    }

    func getTangemPayStatus() async throws -> TangemPayStatus {
        // Since customerInfo polling starts in the init - there is no need to make another call
        for await customerInfo in await customerInfoSubject.compactMap(\.self).values {
            return customerInfo.tangemPayStatus
        }

        // This will never happen since the sequence written above will never be terminated without emitting a value
        return try await customerInfoManagementService.loadCustomerInfo().tangemPayStatus
    }

    @discardableResult
    func loadBalance() -> Task<Void, Never> {
        Task { await setupBalance() }
    }

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never> {
        runTask(in: self) { tangemPayAccount in
            do {
                let customerInfo = try await tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                tangemPayAccount.customerInfoSubject.send(customerInfo)

                if customerInfo.tangemPayStatus.isActive {
                    tangemPayAccount.orderIdStorage.deleteCardIssuingOrderId()
                    await tangemPayAccount.setupBalance()
                }
            } catch {
                VisaLogger.error("Failed to load customer info", error: error)
            }
        }
    }

    func freeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    func unfreeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId, interval: Constants.freezeUnfreezeOrderPollInterval)
        }
    }

    private func startOrderStatusPolling(orderId: String, interval: TimeInterval) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerInfoManagementService] in
                try await customerInfoManagementService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask(in: self) { tangemPayAccount in
            for await result in polling {
                switch result {
                case .success(let order):
                    if order.status == .completed {
                        tangemPayAccount.loadCustomerInfo()
                        return
                    }

                case .failure(let error):
                    VisaLogger.error("Failed to poll order status", error: error)
                    return
                }
            }
        }
    }

    private func createOrder() async {
        do {
            let order = try await customerInfoManagementService.placeOrder(walletAddress: walletAddress)
            orderIdStorage.saveCardIssuingOrderId(order.id)

            startOrderStatusPolling(orderId: order.id, interval: Constants.cardIssuingOrderPollInterval)
        } catch {
            VisaLogger.error("Failed to create order", error: error)
        }
    }

    private func setupBalance() async {
        do {
            balanceSubject.send(.loading)
            let balance = try await customerInfoManagementService.getBalance()
            balanceSubject.send(.success(balance))
        } catch {
            balanceSubject.send(.failure(error))
        }
    }

    private func mapToCard(visaCustomerInfoResponse: VisaCustomerInfoResponse?) -> VisaCustomerInfoResponse.Card? {
        guard let card = customerInfoSubject.value?.card,
              let productInstance = customerInfoSubject.value?.productInstance,
              [.active, .blocked].contains(productInstance.status) else {
            return nil
        }

        return card
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }
}

// MARK: - TangemPayAuthorizationTokensSaver

extension TangemPayAccount: TangemPayAuthorizationTokensSaver {
    func saveAuthorizationTokensToStorage(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {
        try tangemPayAuthorizationTokensRepository.save(tokens: tokens, customerWalletId: customerWalletId)
    }
}

// MARK: - NotificationTapDelegate

extension TangemPayAccount: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPayViewKYCStatus:
            runTask(in: self) { tangemPayAccount in
                do {
                    try await tangemPayAccount.launchKYC {
                        tangemPayAccount.loadCustomerInfo()
                    }
                } catch {
                    VisaLogger.error("Failed to launch KYC", error: error)
                }
            }

        case .tangemPayCreateAccountAndIssueCard:
            didTapIssueOrderSubject.send(())
            runTask(in: self) { tangemPayAccount in
                await tangemPayAccount.createOrder()
            }

        default:
            break
        }
    }
}

// MARK: - TangemPayIssuingManagerDelegated

extension TangemPayAccount: TangemPayIssuingManagerDelegate {
    func createAccountAndIssueCard() {
        didTapIssueOrderSubject.send(())
        runTask(in: self) { tangemPayAccount in
            await tangemPayAccount.createOrder()
        }
    }
}

// MARK: - VisaCustomerInfoResponse+tangemPayStatus

private extension VisaCustomerInfoResponse {
    var tangemPayStatus: TangemPayStatus {
        if let productInstance {
            switch productInstance.status {
            case .active:
                return .active
            case .blocked:
                return .blocked
            default:
                break
            }
        }

        guard case .approved = kyc.status else {
            return .kycRequired
        }

        return .readyToIssueOrIssuing
    }
}

// MARK: - MainHeaderSupplementInfoProvider

extension TangemPayAccount: MainHeaderSupplementInfoProvider {
    var name: String {
        Localization.tangempayTitle
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: nil)
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        .empty
    }
}

private extension TangemPayAccount {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}

struct TangemPayCardDetails {
    let card: VisaCustomerInfoResponse.Card
    let balance: TangemPayBalance
}
