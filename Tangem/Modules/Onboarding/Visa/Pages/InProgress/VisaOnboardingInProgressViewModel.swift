//
//  VisaOnboardingInProgressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol VisaOnboardingInProgressDelegate: VisaOnboardingAlertPresenter {
    func canProceedOnboarding() async throws -> Bool
    @MainActor
    func proceedFromCurrentRemoteState() async
    func openBrowser(at url: URL, onSuccess: @escaping (URL) -> Void)
}

class VisaOnboardingInProgressViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    var title: String {
        state.title
    }

    var description: String {
        state.description
    }

    private let state: State
    private weak var delegate: VisaOnboardingInProgressDelegate?
    private let scheduler = AsyncTaskScheduler()

    private var checkInterval: TimeInterval {
        switch state {
        case .accountDeployment:
            return 10
        case .issuerProcessing:
            return 2
        }
    }

    init(state: VisaOnboardingInProgressViewModel.State, delegate: VisaOnboardingInProgressDelegate?) {
        self.state = state
        self.delegate = delegate
        setupRefresh()
    }

    private func setupRefresh() {
        scheduler.cancel()
        scheduler.scheduleJob(
            interval: checkInterval,
            repeats: true,
            action: weakify(self, forFunction: VisaOnboardingInProgressViewModel.canProceedOnboarding)
        )
    }

    private func canProceedOnboarding() async {
        do {
            if try await delegate?.canProceedOnboarding() ?? false {
                scheduler.cancel()
                await delegate?.proceedFromCurrentRemoteState()
            }
        } catch {
            if !error.isCancellationError {
                scheduler.cancel()
                await delegate?.showAlertAsync(
                    error.alertBinder(
                        okAction: weakify(self, forFunction: VisaOnboardingInProgressViewModel.setupRefresh)
                    )
                )
            }
        }
    }
}

extension VisaOnboardingInProgressViewModel {
    enum State {
        case accountDeployment
        case issuerProcessing

        var title: String {
            switch self {
            case .accountDeployment:
                return "Getting Everything Ready!"
            case .issuerProcessing:
                return "Almost done!"
            }
        }

        // Temp texts
        var description: String {
            switch self {
            case .accountDeployment:
                return "We're working on creating your Blockchain account. Please hang tight!"
            case .issuerProcessing:
                return "Issuer is processing your information. Soon everything will be working as expected."
            }
        }
    }
}
