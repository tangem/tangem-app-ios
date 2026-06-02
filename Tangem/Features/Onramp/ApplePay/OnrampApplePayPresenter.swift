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

    private var currentController: PKPaymentAuthorizationController?
    private var currentProvider: OnrampProvider?
    private var currentOnWillBuy: (() -> Void)?

    init(authorizationHandler: ApplePayButtonPaymentAuthorizationHandler) {
        self.authorizationHandler = authorizationHandler
    }

    @MainActor
    func present(request: PKPaymentRequest, provider: OnrampProvider, onWillBuy: @escaping () -> Void) {
        ExpressLogger.tag("Onramp").info(self, "[Presenter.present] entry provider=\(provider.provider.id) paymentMethod=\(provider.paymentMethod.type) authorizationHandler=\(authorizationHandler == nil ? "nil" : "set")")

        guard currentController == nil else {
            ExpressLogger.warning(self, "present() called while a session is already in flight; ignoring")
            return
        }

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self

        currentController = controller
        currentProvider = provider
        currentOnWillBuy = onWillBuy

        ExpressLogger.tag("Onramp").info(self, "[Presenter.present] calling applePaySheetWillPresent")
        authorizationHandler?.applePaySheetWillPresent()
        controller.present { [weak self] presented in
            ExpressLogger.tag("Onramp").info("[Presenter.present.completion] presented=\(presented)")
            guard !presented else { return }
            Task { @MainActor in
                guard let self else { return }
                ExpressLogger.warning(self, "PKPaymentAuthorizationController.present rejected; releasing session")
                self.releaseSession()
                self.authorizationHandler?.applePaySheetDidFinish()
            }
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
        ExpressLogger.tag("Onramp").info(self, "[Presenter.willAuthorize] onWillBuy=\(currentOnWillBuy == nil ? "nil" : "set")")
        currentOnWillBuy?()
    }

    @MainActor
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        ExpressLogger.tag("Onramp").info(self, "[Presenter.didAuthorize] entry hasToken=\(!payment.token.paymentData.isEmpty) currentProvider=\(currentProvider?.provider.id ?? "nil")")

        guard let currentProvider else {
            assertionFailure("currentProvider must not be nil when didAuthorizePayment fires")
            ExpressLogger.warning(self, "[Presenter.didAuthorize] currentProvider nil; failing completion")
            completion(.init(status: .failure, errors: nil))
            return
        }

        let applePayResult: OnrampApplePayResult
        do {
            applePayResult = try OnrampApplePayUtils.mapPaymentResult(payment)
            ExpressLogger.tag("Onramp").info(self, "[Presenter.didAuthorize] mapPaymentResult success")
        } catch {
            ExpressLogger.warning(self, "[Presenter.didAuthorize] mapPaymentResult threw: \(error.localizedDescription)")
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

        ExpressLogger.tag("Onramp").info(self, "[Presenter.didAuthorize] dispatching to handleApplePayAuthorization")
        authorizationHandler.handleApplePayAuthorization(authorization)
    }

    @MainActor
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        ExpressLogger.tag("Onramp").info(self, "[Presenter.didFinish] controller dismiss requested")
        controller.dismiss { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                ExpressLogger.tag("Onramp").info(self, "[Presenter.didFinish.dismissCompletion] releasing session, calling applePaySheetDidFinish")
                self.releaseSession()
                self.authorizationHandler?.applePaySheetDidFinish()
            }
        }
    }
}
