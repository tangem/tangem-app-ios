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
import WebKit
import UIKit

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

        tangemPayStatusPublisher = customerInfoSubject
            .compactMap(\.self?.tangemPayStatus)
            .eraseToAnyPublisher()

        tangemPayCardIssuingInProgressPublisher = orderIdStorage.cardIssuingOrderIdPublisher
            .map { $0 != nil }
            .merge(with: didTapIssueOrderSubject.mapToValue(true))
            .eraseToAnyPublisher()

        tangemPayCardDetailsPublisher = customerInfoSubject
            .map { customerInfo in
                guard let card = customerInfo?.card,
                      let balance = customerInfo?.balance,
                      let productInstance = customerInfo?.productInstance,
                      [.active, .blocked].contains(productInstance.status)
                else {
                    return nil
                }
                return (card, balance)
            }
            .eraseToAnyPublisher()

        tangemPayNotificationManager = TangemPayNotificationManager(tangemPayStatusPublisher: tangemPayStatusPublisher)

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

        let authorizer = TangemPayAuthorizer(userWalletModel: userWalletModel)

        let tokens = VisaAuthorizationTokens(
            accessToken: nil,
            refreshToken: refreshToken,
            authorizationType: .customerWallet
        )

        self.init(authorizer: authorizer, walletAddress: walletAddress, tokens: tokens)
    }

    @MainActor
    func launchKYC(onClose: (() -> Void)? = nil) async throws {
        let response = try await customerInfoManagementService.loadKYCAccessToken()

        let kycViewController = SumSubKYCViewController(
            accessToken: response.token,
            customerInfoManagementService: customerInfoManagementService,
            onClose: { [weak self] in
                self?.loadCustomerInfo()
                onClose?()
            }
        )

        let navController = UINavigationController(rootViewController: kycViewController)
        navController.modalPresentationStyle = .overFullScreen
        UIApplication.modalFromTop(navController, animated: true)
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

                if customerInfo.tangemPayStatus.isActive {
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
            runTask(in: self) { tangemPayAccount in
                do {
                    try await tangemPayAccount.launchKYC()
                } catch {
                    // [REDACTED_TODO_COMMENT]
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

        return .loaded(text: .string("$" + balance.availableBalance.description))
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        tangemPayCardDetailsPublisher
            .map { cardDetails in
                guard let (_, balance) = cardDetails else {
                    return .loading(cached: nil)
                }

                return .loaded(text: .string("$" + balance.availableBalance.description))
            }
            .eraseToAnyPublisher()
    }
}

private extension TangemPayAccount {
    enum Constants {
        static let cardIssuingOrderPollInterval: TimeInterval = 60
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
    }
}

// MARK: - SumSubEvent

enum SumSubEventType: String {
    case tokenRefreshRequired
    case statusUpdate
}

enum SumSubEvent: String, CaseIterable {
    case onReady
    case onInitialized
    case onStepInitiated
    case onLivenessCompleted
    case onStepCompleted
    case onApplicantLoaded
    case onApplicantSubmitted
    case onError
    case onApplicantStatusChanged
    case onApplicantResubmitted
    case onApplicantActionLoaded
    case onApplicantActionSubmitted
    case onApplicantActionStatusChanged
    case onApplicantActionCompleted
    case moduleResultPresented
    case onResize
    case onVideoIdentCallStarted
    case onVideoIdentModeratorJoined
    case onVideoIdentCompleted
    case onUploadError
    case onUploadWarning
    case onNavigationUiControlsStateChanged
    case onApplicantLevelChanged
}

// MARK: - SumSub KYC ViewController

final class SumSubKYCViewController: UIViewController {
    private let accessToken: String
    private let customerInfoManagementService: any CustomerInfoManagementService
    private let onClose: () -> Void

    private var shouldInitialize = true

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        contentController.add(self, name: SumSubKYCConstants.messageHandlerName)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        return webView
    }()

    init(
        accessToken: String,
        customerInfoManagementService: any CustomerInfoManagementService,
        onClose: @escaping () -> Void
    ) {
        self.accessToken = accessToken
        self.customerInfoManagementService = customerInfoManagementService
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)

        setupLayout()
        loadSumSubSDK()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: closeIcon,
            style: .plain,
            target: self,
            action: #selector(close)
        )
    }

    @objc
    private func close() {
        navigationController?.dismiss(animated: true, completion: onClose)
    }

    private func loadSumSubSDK() {
        let eventsEnumerationString = SumSubEvent.allCases
            .map { "'\($0.rawValue)'" }
            .joined(separator: ", ")

        webView.loadHTMLString(
            SumSubKYCConstants.htmlTemplate(eventsArray: "[\(eventsEnumerationString)]"),
            baseURL: URL(string: "https://localhost") // Use localhost URL as baseURL to enable getUserMedia in WebView
        )
    }
}

// MARK: - WKNavigationDelegate

extension SumSubKYCViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard shouldInitialize else { return }

        shouldInitialize = false
        webView.evaluateJavaScript(SumSubKYCConstants.initSumSubScript(token: accessToken))
    }
}

// MARK: - WKUIDelegate

extension SumSubKYCViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}

// MARK: - WKScriptMessageHandler

extension SumSubKYCViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == SumSubKYCConstants.messageHandlerName,
              let messageBody = message.body as? [String: Any],
              let eventTypeString = messageBody[SumSubKYCConstants.eventTypeKey] as? String,
              let eventType = SumSubEventType(rawValue: eventTypeString)
        else {
            return
        }

        switch eventType {
        case .tokenRefreshRequired:
            handleTokenRefresh()
        case .statusUpdate:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    private func handleTokenRefresh() {
        runTask(in: self) { controller in
            let scriptForEvaluation: String
            do {
                let response = try await controller.customerInfoManagementService.loadKYCAccessToken()
                scriptForEvaluation = SumSubKYCConstants.resolveTokenScript(token: response.token)
            } catch {
                // [REDACTED_TODO_COMMENT]
                scriptForEvaluation = SumSubKYCConstants.rejectTokenScript(errorMessage: "Failed to fetch new token")
            }

            _ = try? await controller.webView.evaluateJavaScript(scriptForEvaluation)
        }
    }
}

// MARK: - SumSubKYCConstants

private enum SumSubKYCConstants {
    static let messageHandlerName = "kycHandler"

    static let eventTypeKey = "eventType"
    static let eventKey = "event"
    static let payloadKey = "payload"

    static func initSumSubScript(token: String) -> String {
        "initSumsub('\(token)');"
    }

    static func resolveTokenScript(token: String) -> String {
        "tokenResolver.resolve('\(token)');"
    }

    static func rejectTokenScript(errorMessage: String) -> String {
        "tokenResolver.reject(new Error('\(errorMessage)'));"
    }

    static func htmlTemplate(eventsArray: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <script src="https://static.sumsub.com/idensic/static/sns-websdk-builder.js"></script>
            <script>
                let tokenResolver = null;

                function requestToken() {
                    return new Promise((resolve, reject) => {
                        tokenResolver = { resolve, reject };
                        window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                            \(eventTypeKey): '\(SumSubEventType.tokenRefreshRequired.rawValue)'
                        });
                    });
                }

                async function initSumsub(accessToken) {
                    if (!accessToken) {
                        accessToken = await requestToken();
                    }

                    let builder = snsWebSdk.init(accessToken, requestToken);

                    \(eventsArray).forEach(eventName => {
                        builder = builder.on('idCheck.' + eventName, (payload) => {
                            window.webkit.messageHandlers.\(messageHandlerName).postMessage({
                                \(eventTypeKey): '\(SumSubEventType.statusUpdate.rawValue)',
                                \(eventKey): eventName,
                                \(payloadKey): payload
                            });
                        });
                    });

                    builder.build().launch('#sumsub-websdk-container');
                }
            </script>
        </head>
        <body>
            <div id="sumsub-websdk-container"/>
        </body>
        </html>
        """
    }
}

import SwiftUI
import TangemAssets
import UIKit

var closeIcon: UIImage {
    Assets.Glyphs.cross20ButtonNew.uiImage
        .withCircleBackground(
            circleSize: 36,
            iconSize: 20,
            circleColor: UIColor(Colors.Button.secondary),
            iconColor: UIColor(Colors.Icon.informative)
        )
}

private extension UIImage {
    func withCircleBackground(
        circleSize: CGFloat,
        iconSize: CGFloat,
        circleColor: UIColor,
        iconColor: UIColor
    ) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: circleSize, height: circleSize))
            .image { context in
                let rect = CGRect(origin: .zero, size: CGSize(width: circleSize, height: circleSize))
                circleColor.setFill()
                context.cgContext.fillEllipse(in: rect)

                let finalIcon = self
                    .withRenderingMode(.alwaysOriginal)
                    .withTintColor(iconColor, renderingMode: .alwaysOriginal)

                let iconOffset = (circleSize - iconSize) / 2
                finalIcon.draw(
                    in: CGRect(
                        x: iconOffset,
                        y: iconOffset,
                        width: iconSize,
                        height: iconSize
                    )
                )
            }
            .withRenderingMode(.alwaysOriginal)
    }
}
