//
//  UserWalletCardScanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import TangemFoundation

class UserWalletCardScanner {
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable
    @Injected(\.globalServicesContext) private var globalServicesContext: GlobalServicesContext
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let scanner: CardScanner

    init(scanner: CardScanner) {
        self.scanner = scanner
    }

    func scanCard() async -> UserWalletCardScanner.Result {
        do {
            let response = try await scanner.scanCardPublisher().async()
            return handleSuccess(response: response)
        } catch {
            return handleFailure(error: error)
        }
    }

    private func handleFailure(error: Error) -> UserWalletCardScanner.Result {
        AppLogger.error(error: error)
        Analytics.error(error: error)

        switch error.toTangemSdkError() {
        case .cardVerificationFailed: // has it's own support button
            return .error(error)
        default:
            failedCardScanTracker.recordFailure()

            if failedCardScanTracker.shouldDisplayAlert {
                return .scanTroubleshooting
            } else {
                return .error(error)
            }
        }
    }

    private func handleSuccess(response: AppScanTaskResponse) -> UserWalletCardScanner.Result {
        failedCardScanTracker.resetCounter()
        Analytics.endLoggingCardScan()

        let cardInfo = response.getCardInfo()
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        if let userWalletId = UserWalletId(config: config) {
            userWalletRepository.updateAssociatedCard(userWalletId: userWalletId, cardId: cardInfo.card.cardId)
        }

        let factory = OnboardingInputFactory(
            userWalletModel: nil,
            sdkFactory: config,
            onboardingStepsBuilderFactory: config
        )

        // need onboarding, update services and exit
        if let onboardingInput = factory.makeOnboardingInput(cardInfo: cardInfo) {
            globalServicesContext.resetServices()
            globalServicesContext.initializeAnalyticsContext(cardInfo: cardInfo)
            return .onboarding(onboardingInput)
        }

        return .success(cardInfo)
    }
}

extension UserWalletCardScanner {
    enum Result {
        case success(CardInfo)
        case error(Error)
        case onboarding(OnboardingInput)
        case scanTroubleshooting
    }
}
