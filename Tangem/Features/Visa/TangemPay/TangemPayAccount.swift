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

    var tangemPayCardDetailsPublisher: AnyPublisher<TangemPayCardDetails?, Never> {
        Publishers
            .CombineLatest(customerInfoSubject, balanceSubject)
            .map { customerInfo, balance in
                guard let card = customerInfo?.card,
                      let balance = balance.value,
                      let productInstance = customerInfo?.productInstance,
                      [.active, .blocked].contains(productInstance.status)
                else {
                    return nil
                }

                return .init(card: card, balance: balance)
            }
            .eraseToAnyPublisher()
    }

    lazy var tangemPayNotificationManager: TangemPayNotificationManager = .init(
        tangemPayStatusPublisher: tangemPayStatusPublisher
    )

    // MARK: - Balances

    lazy var tangemPayTokenBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
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

    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer
    private let walletAddress: String
    private let orderIdStorage: TangemPayOrderIdStorage

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>(.loading)

    private let didTapIssueOrderSubject = PassthroughSubject<Void, Never>()
    private var orderStatusPollingTask: Task<Void, Never>?

    init(authorizer: TangemPayAuthorizer, walletAddress: String, tokens: VisaAuthorizationTokens) {
        self.authorizer = authorizer
        self.walletAddress = walletAddress

        authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                customerWalletAddress: walletAddress,
                authorizationTokens: tokens,
                refreshTokenSaver: nil,
                allowRefresherTask: false
            )

        customerInfoManagementService = VisaCustomerCardInfoProviderBuilder()
            .buildCustomerInfoManagementService(
                authorizationTokensHandler: authorizationTokensHandler,
                authorizeWithCustomerWallet: authorizer.authorizeWithCustomerWallet
            )

        orderIdStorage = TangemPayOrderIdStorage(
            customerWalletAddress: walletAddress,
            appSettings: .shared
        )

        // No reference cycle here, self is stored as weak in both entities
        tangemPayNotificationManager.setupManager(with: self)
        authorizationTokensHandler.setupRefreshTokenSaver(self)

        loadCustomerInfo()

        if let cardIssuingOrderId = orderIdStorage.cardIssuingOrderId {
            startOrderStatusPolling(orderId: cardIssuingOrderId, interval: Constants.cardIssuingOrderPollInterval)
        }
    }

    convenience init?(userWalletModel: UserWalletModel) {
        guard let (walletAddress, refreshToken) = TangemPayUtilities.getWalletAddressAndRefreshToken(keysRepository: userWalletModel.keysRepository) else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(
            interactor: userWalletModel.tangemPayAuthorizingInteractor,
            keysRepository: userWalletModel.keysRepository
        )

        let tokens = VisaAuthorizationTokens(
            accessToken: nil,
            refreshToken: refreshToken,
            authorizationType: .customerWallet
        )

        self.init(authorizer: authorizer, walletAddress: walletAddress, tokens: tokens)
    }

    #if ALPHA || BETA || DEBUG
    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await KYCService.start(
            getToken: customerInfoManagementService.loadKYCAccessToken,
            onDidDismiss: onDidDismiss
        )
    }
    #endif // ALPHA || BETA || DEBUG

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
                async let customerInfo = tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                async let _ = tangemPayAccount.setupBalance()

                try await tangemPayAccount.customerInfoSubject.send(customerInfo)
                if try await customerInfo.tangemPayStatus.isActive {
                    tangemPayAccount.orderIdStorage.deleteCardIssuingOrderId()
                }
            } catch {
                // [REDACTED_TODO_COMMENT]
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

                case .failure:
                    // [REDACTED_TODO_COMMENT]
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
            // [REDACTED_TODO_COMMENT]
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

    deinit {
        orderStatusPollingTask?.cancel()
    }
}

// MARK: - VisaRefreshTokenSaver

extension TangemPayAccount: VisaRefreshTokenSaver {
    func saveRefreshTokenToStorage(refreshToken: String, visaRefreshTokenId: VisaRefreshTokenId) throws {
        try visaRefreshTokenRepository.save(refreshToken: refreshToken, visaRefreshTokenId: visaRefreshTokenId)
    }
}

// MARK: - NotificationTapDelegate

extension TangemPayAccount: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .tangemPayViewKYCStatus:
            #if ALPHA || BETA || DEBUG
            runTask(in: self) { tangemPayAccount in
                do {
                    try await tangemPayAccount.launchKYC {
                        tangemPayAccount.loadCustomerInfo()
                    }
                } catch {
                    // [REDACTED_TODO_COMMENT]
                }
            }
            #endif // ALPHA || BETA || DEBUG

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
