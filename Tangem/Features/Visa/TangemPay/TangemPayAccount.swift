//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import TangemVisa
import TangemSdk
import TangemFoundation
import TangemAssets

final class TangemPayAccount {
    let tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>
    let tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never>

    let tangemPayCardDetailsPublisher: AnyPublisher<(VisaCustomerInfoResponse.Card, TangemPayBalance)?, Never>
    let tangemPayNotificationManager: TangemPayNotificationManager

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

    private let didTapIssueOrderSubject = PassthroughSubject<Void, Never>()
    private var customerInfoPollingTask: Task<Void, Never>?

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

        tangemPayStatusPublisher = customerInfoSubject
            .compactMap(\.self?.tangemPayStatus)
            .eraseToAnyPublisher()

        tangemPayCardIssuingInProgressPublisher = orderIdStorage.savedOrderIdPublisher
            .map { $0 != nil }
            .merge(with: didTapIssueOrderSubject.mapToValue(true))
            .eraseToAnyPublisher()

        tangemPayCardDetailsPublisher = customerInfoSubject
            .map { customerInfo in
                guard let card = customerInfo?.card, let balance = customerInfo?.balance else {
                    return nil
                }
                return (card, balance)
            }
            .eraseToAnyPublisher()

        tangemPayNotificationManager = TangemPayNotificationManager(tangemPayStatusPublisher: tangemPayStatusPublisher)

        // No reference cycle here, self is stored as weak in both entities
        tangemPayNotificationManager.setupManager(with: self)
        authorizationTokensHandler.setupRefreshTokenSaver(self)

        startCustomerInfoPolling()
    }

    convenience init?(userWalletModel: UserWalletModel) {
        guard let (walletAddress, refreshToken) = TangemPayUtilities.getWalletAddressAndRefreshToken(keysRepository: userWalletModel.keysRepository) else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(userWalletModel: userWalletModel)

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
        runTask(in: self) { tangemPayAccount in
            do {
                let balance = try await tangemPayAccount.customerInfoManagementService.getBalance()
                tangemPayAccount.customerInfoSubject.send(
                    tangemPayAccount.customerInfoSubject.value?.withBalance(balance)
                )
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    @discardableResult
    func loadCustomerInfo() -> Task<Void, Never> {
        runTask(in: self) { tangemPayAccount in
            do {
                let customerInfo = try await tangemPayAccount.customerInfoManagementService.loadCustomerInfo()
                tangemPayAccount.customerInfoSubject.send(customerInfo)
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    func freeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.freeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId)
        }
    }

    func unfreeze(cardId: String) async throws {
        let response = try await customerInfoManagementService.unfreeze(cardId: cardId)
        if response.status != .completed {
            startOrderStatusPolling(orderId: response.orderId)
        }
    }

    private func startOrderStatusPolling(orderId: String) {
        let polling = PollingSequence(
            interval: 5,
            request: { [weak self] in
                try await self?.customerInfoManagementService.getOrder(orderId: orderId)
            }
        )

        runTask(in: self) { tangemPayAccount in
            for await result in polling {
                switch result {
                case .success(let order):
                    guard let order else {
                        return
                    }

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

    private func startCustomerInfoPolling() {
        customerInfoPollingTask?.cancel()

        let polling = PollingSequence(
            interval: .minute,
            request: { [weak self] in
                try await self?.customerInfoManagementService.loadCustomerInfo()
            }
        )

        customerInfoPollingTask = runTask(in: self) { tangemPayAccount in
            for await result in polling {
                switch result {
                case .success(let customerInfo):
                    guard let customerInfo else {
                        tangemPayAccount.customerInfoPollingTask?.cancel()
                        return
                    }

                    tangemPayAccount.customerInfoSubject.send(customerInfo)
                    if customerInfo.tangemPayStatus.isActive {
                        tangemPayAccount.orderIdStorage.deleteSavedOrderId()
                        tangemPayAccount.customerInfoPollingTask?.cancel()
                    }

                case .failure:
                    // [REDACTED_TODO_COMMENT]
                    break
                }
            }
        }
    }

    private func createOrder() async {
        do {
            let order = try await customerInfoManagementService.placeOrder(walletAddress: walletAddress)
            orderIdStorage.saveOrderId(order.id)
        } catch {
            // [REDACTED_TODO_COMMENT]
        }
    }

    deinit {
        customerInfoPollingTask?.cancel()
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
            default:
                return .blocked
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
        // [REDACTED_TODO_COMMENT]
        "Tangem Pay"
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: nil)
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        .empty
    }
}

// MARK: - MainHeaderSubtitleProvider

extension TangemPayAccount: MainHeaderSubtitleProvider {
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        tangemPayCardDetailsPublisher
            .map { cardDetails -> MainHeaderSubtitleInfo in
                guard let (_, balance) = cardDetails else {
                    return .init(messages: [], formattingOption: .default)
                }

                // [REDACTED_TODO_COMMENT]
                return .init(messages: ["\(balance.availableBalance.description) \(balance.currency)"], formattingOption: .default)
            }
            .eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool {
        false
    }
}

// MARK: - MainHeaderBalanceProvider

extension TangemPayAccount: MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State {
        guard let balance = customerInfoSubject.value?.balance else {
            return .loading(cached: nil)
        }

        // [REDACTED_TODO_COMMENT]
        return .loaded(text: .string("$" + balance.availableBalance.description))
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        tangemPayCardDetailsPublisher
            .map { cardDetails in
                guard let (_, balance) = cardDetails else {
                    return .loading(cached: nil)
                }

                // [REDACTED_TODO_COMMENT]
                return .loaded(text: .string("$" + balance.availableBalance.description))
            }
            .eraseToAnyPublisher()
    }
}
