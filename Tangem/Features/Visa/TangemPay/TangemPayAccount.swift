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

final class TangemPayAccount {
    let tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>
    let tangemPayCardIssuingInProgress: AnyPublisher<Bool, Never>

    let tangemPayNotificationManager: TangemPayNotificationManager

    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    private let authorizationTokensHandler: VisaAuthorizationTokensHandler
    private let authorizer: TangemPayAuthorizer
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let orderIdStorage: TangemPayOrderIdStorage

    private let customerInfoSubject = CurrentValueSubject<VisaCustomerInfoResponse?, Never>(nil)
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

        tangemPayCardIssuingInProgress = orderIdStorage.savedOrderIdPublisher
            .map { $0 != nil }
            .merge(with: didTapIssueOrderSubject.mapToValue(true))
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
        try await getCustomerInfo().tangemPayStatus
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

    private func prepareTokensHandler() async throws {
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
