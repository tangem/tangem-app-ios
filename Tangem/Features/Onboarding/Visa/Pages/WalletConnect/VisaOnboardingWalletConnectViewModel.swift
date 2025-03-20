//
//  VisaOnboardingWalletConnectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemVisa
import TangemFoundation

class VisaOnboardingWalletConnectViewModel: ObservableObject {
    private var delegate: VisaOnboardingInProgressDelegate?

    private let statusUpdateTimeIntervalSec: TimeInterval = 10

    private var scheduler = AsyncTaskScheduler()

    init(delegate: VisaOnboardingInProgressDelegate? = nil) {
        self.delegate = delegate
    }

    func openBrowser() {
        let visaURL = VisaUtilities().walletConnectURL
        delegate?.openBrowser(at: visaURL, onSuccess: { [weak self] successURL in
            self?.proceedOnboardingIfPossible()
        })
        setupStatusUpdateTask()
    }

    func openShareSheet() {
        let visaURL = VisaUtilities().walletConnectURL
        // [REDACTED_TODO_COMMENT]
        let av = UIActivityViewController(activityItems: [visaURL], applicationActivities: nil)
        AppPresenter.shared.show(av)
        setupStatusUpdateTask()
    }

    func cancelStatusUpdates() {
        scheduler.cancel()
    }

    private func setupStatusUpdateTask() {
        scheduler.scheduleJob(interval: statusUpdateTimeIntervalSec, repeats: true) { [weak self] in
            do {
                guard try await self?.delegate?.canProceedOnboarding() ?? false else {
                    return
                }

                await self?.proceedOnboarding()
            } catch {
                VisaLogger.error("Failed to check if onboarding can proceed", error: error)
                self?.scheduler.cancel()
                await self?.delegate?.showContactSupportAlert(for: error)
            }
        }
    }

    private func proceedOnboardingIfPossible() {
        runTask(in: self, isDetached: false) { viewModel in
            do {
                if try await viewModel.delegate?.canProceedOnboarding() ?? false {
                    await viewModel.proceedOnboarding()
                } else {
                    viewModel.setupStatusUpdateTask()
                }
            } catch {
                VisaLogger.error("Failed to check if onboarding can proceed", error: error)
                await viewModel.delegate?.showContactSupportAlert(for: error)
            }
        }
    }

    @MainActor
    private func proceedOnboarding() async {
        cancelStatusUpdates()
        await delegate?.proceedFromCurrentRemoteState()
    }
}
