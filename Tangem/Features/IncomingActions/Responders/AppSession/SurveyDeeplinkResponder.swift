//
//  SurveyDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SurveySparrowSdk

/// Shows the survey a `tangem://survey` deeplink names, from wherever the user is. Not a screen of ours but one
/// the SDK draws, which is why it goes up on its own instead of through the presenter that builds our screens.
final class SurveyDeeplinkResponder {
    @Injected(\.keysManager) private var keysManager: any KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
}

// MARK: - IncomingActionResponder

extension SurveyDeeplinkResponder: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(.survey(let deeplink)) = action else {
            return false
        }

        // Incoming actions are dispatched on the main thread, and so is everything a deeplink reads on its way
        // to a screen.
        MainActor.assumeIsolated {
            DeeplinkFloatingSheet.dismissActive()
            show(token: deeplink.token)
        }

        return true
    }
}

// MARK: - Private

@MainActor
private extension SurveyDeeplinkResponder {
    func show(token: String) {
        let surveyViewController = SsSurveyViewController()
        surveyViewController.domain = keysManager.surveySparrow.domain
        surveyViewController.token = token
        // `.CLASSIC` controls the SDK rendering mode (full-screen survey UI).
        // The survey methodology (NPS / CSAT / CES) is determined by the token
        // on SurveySparrow's side, not by this flag.
        surveyViewController.surveyType = .CLASSIC

        // The same wallet identifier that Customer.io and Amplitude use as the user id,
        // so survey responses can be joined with the push/banner funnel across platforms.
        if let userWalletId = userWalletRepository.selectedModel?.userWalletId {
            surveyViewController.params = ["wallet_id": userWalletId.hashedStringValue]
        }

        AppPresenter.shared.show(surveyViewController)
    }
}
