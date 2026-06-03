//
//  OnrampApplePayPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import PassKit
import TangemExpress

protocol OnrampApplePayPresenting: AnyObject {
    @MainActor
    func present(request: PKPaymentRequest, provider: OnrampProvider, onWillBuy: @escaping () -> Void)
}

final class OnrampApplePayPresenter: NSObject, OnrampApplePayPresenting, @unchecked Sendable {
    private weak var authorizationHandler: ApplePayButtonPaymentAuthorizationHandler?
    private let analyticsLogger: any SendOnrampNAPAnalyticsLogger

    private var currentController: PKPaymentAuthorizationController?
    private var currentProvider: OnrampProvider?
    private var currentOnWillBuy: (() -> Void)?

    init(
        authorizationHandler: ApplePayButtonPaymentAuthorizationHandler,
        analyticsLogger: any SendOnrampNAPAnalyticsLogger
    ) {
        self.authorizationHandler = authorizationHandler
        self.analyticsLogger = analyticsLogger
    }

    @MainActor
    func present(request: PKPaymentRequest, provider: OnrampProvider, onWillBuy: @escaping () -> Void) {
        guard currentController == nil else {
            ExpressLogger.warning(self, "present() called while a session is already in flight; ignoring")
            return
        }

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self

        currentController = controller
        currentProvider = provider
        currentOnWillBuy = onWillBuy

        authorizationHandler?.applePaySheetWillPresent()
        controller.present { [weak self] presented in
            guard presented else {
                Task { @MainActor in
                    guard let self else { return }
                    ExpressLogger.warning(self, "PKPaymentAuthorizationController.present rejected; releasing session")
                    self.releaseSession()
                    self.authorizationHandler?.applePaySheetDidFinish()
                }
                return
            }
            self?.analyticsLogger.logOnrampNAPScreenOpened()
        }
    }

    @MainActor
    private func releaseSession() {
        currentController = nil
        currentProvider = nil
        currentOnWillBuy = nil
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension OnrampApplePayPresenter: PKPaymentAuthorizationControllerDelegate {
    @MainActor
    func paymentAuthorizationControllerWillAuthorizePayment(_ controller: PKPaymentAuthorizationController) {
        currentOnWillBuy?()
    }

    @MainActor
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard let currentProvider else {
            assertionFailure("currentProvider must not be nil when didAuthorizePayment fires")
            completion(.init(status: .failure, errors: nil))
            return
        }

        let applePayResult: OnrampApplePayResult
        do {
            applePayResult = try OnrampApplePayUtils.mapPaymentResult(payment)
        } catch {
            completion(.init(status: .failure, errors: [error]))
            return
        }

        let authorization = ApplePayAuthorizationResult(
            provider: currentProvider,
            applePayResult: applePayResult,
            resultHandler: completion
        )

        guard let authorizationHandler else {
            ExpressLogger.warning(self, "authorizationHandler deallocated before authorization completed")
            authorization.fail()
            return
        }

        authorizationHandler.handleApplePayAuthorization(authorization)
    }

    @MainActor
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.releaseSession()
                self.authorizationHandler?.applePaySheetDidFinish()
            }
        }
    }
}
