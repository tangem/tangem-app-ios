//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemSdk
import TangemFoundation
import TangemAssets

final class TangemPayAccount {
    let tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>
    let tangemPayCardIssuingInProgressPublisher: AnyPublisher<Bool, Never>

    let tangemPayCardDetailsPublisher: AnyPublisher<(VisaCustomerInfoResponse.Card, TangemPayBalance)?, Never>
    let tangemPayBalancePublisher: AnyPublisher<TangemPayBalance?, Never>

    let tangemPayNotificationManager: TangemPayNotificationManager

    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer
    let customerInfoManagementService: any CustomerInfoManagementService
    private let orderIdStorage: TangemPayOrderIdStorage

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
    private let balanceSubject = CurrentValueSubject<TangemPayBalance?, Never>(nil)
    private let transactionHistorySubject = CurrentValueSubject<TangemPayTransactionHistoryResponse?, Never>(nil)

    private let didTapIssueOrderSubject = PassthroughSubject<Void, Never>()
    private var customerInfoPollingTask: Task<Void, Never>?

    init(authorizer: TangemPayAuthorizer, tokens: VisaAuthorizationTokens) {
        self.authorizer = authorizer

        authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder()
            .build(
                customerWalletAddress: authorizer.walletModel.defaultAddressString,
                authorizationTokens: tokens,
                refreshTokenSaver: nil
            )

        customerInfoManagementService = VisaCustomerCardInfoProviderBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        orderIdStorage = TangemPayOrderIdStorage(
            customerWalletAddress: authorizer.walletModel.defaultAddressString,
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

        tangemPayBalancePublisher = balanceSubject
            .merge(with: customerInfoSubject.map(\.?.balance))
            .removeDuplicates()
            .eraseToAnyPublisher()

        tangemPayNotificationManager = TangemPayNotificationManager(tangemPayStatusPublisher: tangemPayStatusPublisher)

        // No reference cycle here, self is stored as weak in both entities
        tangemPayNotificationManager.setupManager(with: self)
        authorizationTokensHandler.setupRefreshTokenSaver(self)

        startCustomerInfoPolling()
    }

    convenience init?(walletModel: any WalletModel) {
        guard walletModel.tokenItem.blockchain == VisaUtilities.visaBlockchain else {
            return nil
        }

        @Injected(\.visaRefreshTokenRepository) var visaRefreshTokenRepository: VisaRefreshTokenRepository
        let visaRefreshTokenId = VisaRefreshTokenId.customerWalletAddress(walletModel.defaultAddressString)

        // If there was no refreshToken saved - means user never got tangem pay offer
        guard let refreshToken = visaRefreshTokenRepository.getToken(forVisaRefreshTokenId: visaRefreshTokenId) else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(walletModel: walletModel)

        let tokens = VisaAuthorizationTokens(
            accessToken: nil,
            refreshToken: refreshToken,
            authorizationType: .customerWallet
        )

        self.init(authorizer: authorizer, tokens: tokens)
    }

    convenience init?(userWalletModel: UserWalletModel) {
        guard let walletModel = userWalletModel.visaWalletModel else {
            return nil
        }

        self.init(walletModel: walletModel)
    }

    #if ALPHA || BETA || DEBUG
    func launchKYC(onDidDismiss: @escaping () -> Void) async throws {
        try await prepareTokensHandler()

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
        return try await getCustomerInfo().tangemPayStatus
    }

    @discardableResult
    func loadBalance() -> Task<Void, Never> {
        runTask(in: self) { tangemPayAccount in
            do {
                try await tangemPayAccount.prepareTokensHandler()
                let balance = try await tangemPayAccount.customerInfoManagementService.getBalance()
                tangemPayAccount.balanceSubject.send(balance)
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    private func startCustomerInfoPolling() {
        customerInfoPollingTask?.cancel()

        let polling = PollingSequence(
            interval: .minute,
            request: { [weak self] in
                try await self?.getCustomerInfo()
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

    private func reloadCustomerInfo() {
        runTask(in: self) { tangemPayAccount in
            let customerInfo = try await tangemPayAccount.getCustomerInfo()
            tangemPayAccount.customerInfoSubject.send(customerInfo)
        }
    }

    private func getCustomerInfo() async throws -> VisaCustomerInfoResponse {
        try await prepareTokensHandler()
        return try await customerInfoManagementService.loadCustomerInfo()
    }

    func prepareTokensHandler() async throws {
        if await authorizationTokensHandler.refreshTokenExpired {
            let tokens = try await authorizer.authorizeWithCustomerWallet()
            try await authorizationTokensHandler.setupTokens(tokens)
        }

        if await authorizationTokensHandler.accessTokenExpired {
            try await authorizationTokensHandler.forceRefreshToken()
        }
    }

    private func createOrder() async {
        do {
            try await prepareTokensHandler()
            let order = try await customerInfoManagementService.placeOrder(walletAddress: authorizer.walletModel.defaultAddressString)

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
                        tangemPayAccount.reloadCustomerInfo()
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

extension TangemPayAccount: MainHeaderSupplementInfoProvider {
    var name: String {
        "Tangem Pay"
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: nil)
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        .empty
    }
}

extension TangemPayAccount: MainHeaderSubtitleProvider {
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        tangemPayBalancePublisher
            .map { balance -> MainHeaderSubtitleInfo in
                guard let balance else {
                    return .init(messages: [], formattingOption: .default)
                }

                return .init(messages: ["\(balance.availableBalance.description) \(balance.currency)"], formattingOption: .default)
            }
            .eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool {
        false
    }
}

extension TangemPayAccount: MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State {
        guard let balance = balanceSubject.value ?? customerInfoSubject.value?.balance else {
            return .loading(cached: nil)
        }
        return .loaded(text: .string("$" + balance.availableBalance.description))
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        tangemPayBalancePublisher
            .map { balance in
                guard let balance else {
                    return .loading(cached: nil)
                }
                return .loaded(text: .string("$" + balance.availableBalance.description))
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - VisaCustomerInfoResponse+tangemPayStatus

private extension VisaCustomerInfoResponse {
    var tangemPayStatus: TangemPayStatus {
        if let productInstance, productInstance.status == .active {
            return .active
        }

        guard case .approved = kyc.status else {
            return .kycRequired
        }

        return .readyToIssueOrIssuing
    }
}
