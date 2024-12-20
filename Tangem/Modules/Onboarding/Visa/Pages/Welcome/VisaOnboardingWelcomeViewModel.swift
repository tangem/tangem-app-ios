//
//  VisaOnboardingWelcomeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemFoundation

protocol VisaOnboardingWelcomeDelegate: VisaOnboardingAlertPresenter {
    func openAccessCodeScreen()
    func continueActivation() async throws
}

class VisaOnboardingWelcomeViewModel: ObservableObject {
    @Published var cardImage: Image?
    @Published var isLoading: Bool = false

    let isAccessCodeSet: Bool

    var title: String {
        activationState.greetingsText(userName: userName)
    }

    var description: String {
        activationState.activationDescriptionText
    }

    var activationButtonTitle: String {
        activationState.activationButtonTitle
    }

    private let activationState: State
    private let userName: String
    private weak var delegate: VisaOnboardingWelcomeDelegate?

    init(
        activationState: State,
        isAccessCodeSet: Bool,
        userName: String,
        imagePublisher: some Publisher<Image?, Never>,
        delegate: VisaOnboardingWelcomeDelegate?
    ) {
        self.activationState = activationState
        self.isAccessCodeSet = isAccessCodeSet
        self.userName = userName
        self.delegate = delegate
        var cancellable: AnyCancellable?
        cancellable = imagePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, image in
                viewModel.cardImage = image
                withExtendedLifetime(cancellable) {}
            }
    }

    func mainButtonAction() {
        switch activationState {
        case .newActivation:
            delegate?.openAccessCodeScreen()
        case .continueActivation:
            if isAccessCodeSet {
                continueActivation()
            } else {
                delegate?.openAccessCodeScreen()
            }
        }
    }

    private func continueActivation() {
        isLoading = true
        runTask(in: self, isDetached: false) { viewModel in
            do {
                try await viewModel.delegate?.continueActivation()
            } catch {
                if !error.isCancellationError {
                    await viewModel.delegate?.showAlert(error.alertBinder)
                }
            }
            await runOnMain {
                viewModel.isLoading = false
            }
        }
    }
}

extension VisaOnboardingWelcomeViewModel {
    // NOTE: All text messages will be changed later they are not final,
    // some of them right now is: "Bla bla bla bla"
    enum State {
        case newActivation
        case continueActivation

        var activationButtonTitle: String {
            switch self {
            case .newActivation:
                return "Start Activation"
            case .continueActivation:
                return "Continue Activation"
            }
        }

        var activationDescriptionText: String {
            switch self {
            case .newActivation:
                return "Start your activation process by filling some information"
            case .continueActivation:
                return "Welcome back, lets continue your activation process by filling some information, signing some contracts and so on"
            }
        }

        func greetingsText(userName: String) -> String {
            switch self {
            case .newActivation:
                return "Hello, \(userName)"
            case .continueActivation:
                return "Welcome back, \(userName)"
            }
        }
    }
}
