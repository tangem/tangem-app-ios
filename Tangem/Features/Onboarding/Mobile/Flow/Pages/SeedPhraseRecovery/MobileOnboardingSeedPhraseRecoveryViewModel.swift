//
//  MobileOnboardingSeedPhraseRecoveryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk
import struct TangemUIUtils.AlertBinder

final class MobileOnboardingSeedPhraseRecoveryViewModel: ObservableObject {
    @Published var state: State?
    @Published var alert: AlertBinder?

    let continueButtonTitle = Localization.commonContinue
    let responsibilityDescription = Localization.backupSeedResponsibility

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()
    private var isFirstAppeared: Bool = true

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private weak var delegate: MobileOnboardingSeedPhraseRecoveryDelegate?

    var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingSeedPhraseRecoveryDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.delegate = delegate
        bind()
        setup()
    }
}

extension MobileOnboardingSeedPhraseRecoveryViewModel {
    func onAppear() {
        guard isFirstAppeared else { return }
        isFirstAppeared = false
        logScreenOpenedAnalytics()
    }

    func onContinueTap() {
        delegate?.seedPhraseRecoveryContinue()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseRecoveryViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingSeedScreenshotAlert)
                viewModel.logScreenCaptureAnalytics()
            }
            .store(in: &bag)
    }

    func setup() {
        runTask(in: self) { viewModel in
            do {
                let context = try viewModel.mobileWalletSdk.validate(auth: .none, for: viewModel.userWalletModel.userWalletId)
                let mnemonic = try viewModel.mobileWalletSdk.exportMnemonic(context: context)
                await viewModel.setupState(mnemonic: mnemonic)
            } catch {
                AppLogger.error("Export mnemonic to recovery failed:", error: error)
            }
        }
    }

    @MainActor
    func setupState(mnemonic: [String]) {
        let item = StateItem(
            info: makeInfoItem(mnemonic: mnemonic),
            phrase: makePhraseItem(mnemonic: mnemonic)
        )
        state = .item(item)
    }

    func makeInfoItem(mnemonic: [String]) -> InfoItem {
        InfoItem(
            title: Localization.backupSeedTitle,
            description: Localization.backupSeedDescription(mnemonic.count)
        )
    }

    func makePhraseItem(mnemonic: [String]) -> PhraseItem {
        let wordsHalfCount = mnemonic.count / 2
        return PhraseItem(
            words: mnemonic,
            firstRange: 0 ..< wordsHalfCount,
            secondRange: wordsHalfCount ..< mnemonic.count
        )
    }
}

// MARK: - Analytics

private extension MobileOnboardingSeedPhraseRecoveryViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(
            .walletSettingsRecoveryPhraseScreen,
            params: source.analyticsParams,
            contextParams: analyticsContextParams
        )
    }

    func logScreenCaptureAnalytics() {
        Analytics.log(.onboardingSeedScreenCapture, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileOnboardingSeedPhraseRecoveryViewModel {
    enum State {
        case item(StateItem)
    }

    struct StateItem {
        let info: InfoItem
        let phrase: PhraseItem
    }

    struct InfoItem {
        let title: String
        let description: String
    }

    struct PhraseItem {
        let words: [String]
        let firstRange: Range<Int>
        let secondRange: Range<Int>
    }
}
