//
//  TangemPayAddPaymentPassPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import PassKit
import TangemUIUtils
import UIKit

final class TangemPayAddPaymentPassPresenter: NSObject {
    private let tokenizationService: TangemPayCardTokenizationService
    private let tokenizationReceipt: String

    private var tokenizationServiceError: TangemPayCardTokenizationError?
    private var continuation: CheckedContinuation<
        Result<PKSecureElementPass.PassActivationState, TangemPayAppleWalletProvisioningError>,
        Never
    >?

    init(tokenizationService: TangemPayCardTokenizationService, tokenizationReceipt: String) {
        self.tokenizationService = tokenizationService
        self.tokenizationReceipt = tokenizationReceipt
    }

    @MainActor
    func present(
        requestConfiguration: PKAddPaymentPassRequestConfiguration
    ) async throws(TangemPayAppleWalletProvisioningError) -> PKSecureElementPass.PassActivationState {
        guard let controller = PKAddPaymentPassViewController(requestConfiguration: requestConfiguration, delegate: self) else {
            throw .presentationUnavailable
        }

        tokenizationServiceError = nil

        UIApplication.modalFromTop(controller)

        let result = await withCheckedContinuation { continuation in
            self.continuation = continuation
        }

        return try result.get()
    }
}

// MARK: - PKAddPaymentPassViewControllerDelegate

extension TangemPayAddPaymentPassPresenter: PKAddPaymentPassViewControllerDelegate {
    func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        generateRequestWithCertificateChain certificates: [Data],
        nonce: Data,
        nonceSignature: Data,
        completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void
    ) {
        Task { @MainActor [tokenizationService, tokenizationReceipt] in
            do throws(TangemPayCardTokenizationError) {
                let request = try await tokenizationService.completeTokenization(
                    tokenizationReceipt: tokenizationReceipt,
                    certificates: certificates,
                    nonce: nonce,
                    nonceSignature: nonceSignature
                )
                handler(request)
            } catch {
                tokenizationServiceError = error
                handler(PKAddPaymentPassRequest())
            }
        }
    }

    func addPaymentPassViewController(_ controller: PKAddPaymentPassViewController, didFinishAdding pass: PKPaymentPass?, error: Error?) {
        controller.dismiss(animated: true)

        guard let continuation = continuation.take() else { return }

        if let pass {
            continuation.resume(returning: .success(pass.passActivationState))
        } else if let tokenizationServiceError {
            continuation.resume(returning: .failure(.tokenization(tokenizationServiceError)))
        } else if let error {
            continuation.resume(returning: .failure(.passKit(error)))
        } else {
            continuation.resume(returning: .failure(.unknownError))
        }
    }
}
