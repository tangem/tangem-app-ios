//
//  PolymarketWelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

final class PolymarketWelcomeViewModel: ObservableObject {
    @Published private(set) var runState: RunState = .idle
    @Published var alert: AlertBinder?

    let copy: PolymarketWelcomeCopy

    var isRunning: Bool { runState != .idle }

    private let interactor: PolymarketOnboardingInteractor
    private weak var coordinator: PolymarketWelcomeRoutable?

    init(
        interactor: PolymarketOnboardingInteractor,
        hasExistingAccount: Bool,
        coordinator: PolymarketWelcomeRoutable
    ) {
        self.interactor = interactor
        self.coordinator = coordinator

        copy = PolymarketWelcomeCopy(hasExistingAccount: hasExistingAccount)
    }
}

// MARK: - Actions

extension PolymarketWelcomeViewModel {
    func onStartTap() {
        guard !isRunning else { return }

        runState = .deriving

        runTask(in: self) { @MainActor viewModel in
            for await progress in viewModel.interactor.onboard() {
                viewModel.handle(progress)
            }

            viewModel.runState = .idle
        }
    }

    func onCloseTap() {
        coordinator?.dismiss()
    }

    func onLegalTermsTap(url: URL) {
        coordinator?.openLegalTerms(url: url)
    }
}

// MARK: - Progress handling

private extension PolymarketWelcomeViewModel {
    @MainActor
    func handle(_ progress: PolymarketOnboardingProgress) {
        switch progress {
        case .deriving:
            runState = .deriving
        case .awaitingSignature:
            runState = .awaitingSignature
        case .working:
            runState = .working
        case .ready(let isNewAccount):
            guard let coordinator else { return }

            presentAccountCreatedToast()
            coordinator.onboardingDidFinish(isNewAccount: isNewAccount)
        case .handedOff:
            break
        case .failed(let error):
            handle(error)
        }
    }

    @MainActor
    func handle(_ error: PolymarketOnboardingError) {
        switch error {
        case .regionBlocked:
            coordinator?.openRegionWarning()
        case _ where error.isRetryable:
            presentRetryAlert()
        default:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.commonUnknownError)
        }
    }
}

// MARK: - Notices

private extension PolymarketWelcomeViewModel {
    @MainActor
    func presentAccountCreatedToast() {
        // [REDACTED_TODO_COMMENT]
        Toast(view: SuccessToast(text: "Prediction account is ready"))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    @MainActor
    func presentRetryAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.commonTryAgainLater,
            primaryButton: .default(Text(Localization.alertButtonTryAgain)) { [weak self] in self?.onStartTap() },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Auxiliary types

extension PolymarketWelcomeViewModel {
    enum RunState: Equatable {
        case idle
        case deriving
        case awaitingSignature
        case working
    }
}

// MARK: - Constants

extension PolymarketWelcomeViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 52
    }
}
