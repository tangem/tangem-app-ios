//
//  TangemPayActivateCardViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils

final class TangemPayActivateCardViewModel: ObservableObject, Identifiable {
    @Published private(set) var digits = ""
    @Published private(set) var isActivating = false
    @Published private(set) var isEntryFocused = false
    @Published var alert: AlertBinder?

    @Published private var hintError: String?

    let digitCount = Constants.digitCount
    let activationImageURL: URL?

    var hint: String {
        if let hintError {
            return hintError
        }

        return isActivating
            ? Localization.tangempayCardActivationInProgress
            : Localization.tangempayCardActivationDescription
    }

    var isContinueEnabled: Bool {
        digits.count == digitCount
    }

    var isHintError: Bool {
        hintError != nil
    }

    private let productInstanceId: String
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayActivateCardRoutable?
    private var activationTask: Task<Void, Never>?

    init(
        productInstanceId: String,
        activationImageURL: URL?,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayActivateCardRoutable?
    ) {
        self.productInstanceId = productInstanceId
        self.activationImageURL = activationImageURL
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        Analytics.log(.visaPlasticCardActivationScreenOpened)
    }

    func focusEntry() {
        isEntryFocused = true
    }

    /// The keypad stays up through the request, so the digits freeze instead of the field being dismissed.
    func updateDigits(_ digits: String) {
        guard !isActivating else { return }

        if digits.count == digitCount, self.digits.count < digitCount {
            Analytics.log(.visaPlasticCardLast4DigitsEntered)
        }

        self.digits = digits
        hintError = nil
    }

    func activate() {
        guard isContinueEnabled, !isActivating else { return }

        Analytics.log(.visaPlasticActivationContinueClicked)
        isActivating = true
        hintError = nil

        activationTask = runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.tangemPayAccount.activatePlasticCard(
                    productInstanceId: viewModel.productInstanceId,
                    lastFourDigits: viewModel.digits
                )
            } catch {
                guard !Task.isCancelled else { return }

                viewModel.isActivating = false
                viewModel.handle(ActivationFailure(error))
                return
            }

            guard !Task.isCancelled else { return }

            Analytics.log(.visaPlasticCardActivationSuccess)
            viewModel.coordinator?.activateCardDidFinish()
        }
    }

    func close() {
        activationTask?.cancel()
        isEntryFocused = false
        coordinator?.closeActivateCard()
    }
}

// MARK: - Errors

private extension TangemPayActivateCardViewModel {
    enum ActivationFailure {
        case invalidCardData
        case cardNotPhysical
        case cardAlreadyActive
        case cardNotReady
        case activeOrderExists
        case unspecified

        init(_ error: any Error) {
            self = switch (error as? TangemPayAPIServiceError)?.apiErrorCode {
            case TangemPayAPIError.Code.cardActivationInvalidCardData: .invalidCardData
            case TangemPayAPIError.Code.cardActivationCardNotPhysical: .cardNotPhysical
            case TangemPayAPIError.Code.cardActivationCardAlreadyActive: .cardAlreadyActive
            case TangemPayAPIError.Code.cardActivationCardNotReady: .cardNotReady
            case TangemPayAPIError.Code.cardActivationActiveOrderExists: .activeOrderExists
            default: .unspecified
            }
        }

        var message: String {
            switch self {
            case .invalidCardData: Localization.tangempayCardActivationError
            case .cardNotPhysical: Localization.tangempayCardActivationErrorNotPhysical
            case .cardAlreadyActive: Localization.tangempayCardActivationErrorAlreadyActive
            case .cardNotReady: Localization.tangempayCardActivationErrorNotReady
            case .activeOrderExists: Localization.tangempayCardActivationErrorInProgress
            case .unspecified: Localization.commonSomethingWentWrong
            }
        }

        var closesFlow: Bool {
            switch self {
            case .cardNotPhysical, .cardAlreadyActive, .cardNotReady, .activeOrderExists: true
            case .invalidCardData, .unspecified: false
            }
        }
    }

    func handle(_ failure: ActivationFailure) {
        switch failure {
        case .invalidCardData:
            Analytics.log(.visaPlasticLast4DigitsValidationErrorShowed)
            digits = ""
            hintError = failure.message
            return
        case .cardAlreadyActive, .activeOrderExists:
            runTask { [tangemPayAccount] in await tangemPayAccount.loadCustomerInfo() }
        case .cardNotPhysical, .cardNotReady, .unspecified:
            break
        }

        alert = AlertBinder(alert: Alert(
            title: Text(failure.message),
            dismissButton: .default(Text(Localization.commonOk)) { [weak self] in
                guard failure.closesFlow else { return }

                self?.close()
            }
        ))
    }
}

// MARK: - Constants

private extension TangemPayActivateCardViewModel {
    enum Constants {
        static let digitCount = 4
    }
}
