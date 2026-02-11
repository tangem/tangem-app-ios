//
//  MobileOnboardingSeedPhraseValidationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseValidationViewModel: ObservableObject {
    @Published var state: State?

    let navigationTitle = Localization.commonBackup

    private let mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()
    private var isFirstAppeared: Bool = true

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private weak var delegate: MobileOnboardingSeedPhraseValidationDelegate?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingSeedPhraseValidationDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.delegate = delegate
        setup()
    }
}

// MARK: - Internal methods

extension MobileOnboardingSeedPhraseValidationViewModel {
    func onAppear() {
        guard isFirstAppeared else { return }
        isFirstAppeared = false
        logScreenOpenedAnalytics()
    }

    func onCreateWallet() {
        delegate?.didValidateSeedPhrase()
    }

    func onBackTap() {
        delegate?.onSeedPhraseValidationBack()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseValidationViewModel {
    func setup() {
        runTask(in: self) { viewModel in
            do {
                let context = try viewModel.mobileWalletSdk.validate(auth: .none, for: viewModel.userWalletModel.userWalletId)
                let mnemonic = try viewModel.mobileWalletSdk.exportMnemonic(context: context)
                let item = StateItem(second: mnemonic[1], seventh: mnemonic[6], eleventh: mnemonic[10])

                await runOnMain {
                    viewModel.state = .item(item)
                }
            } catch {
                AppLogger.error("Export mnemonic to validate failed:", error: error)
            }
        }
    }
}

// MARK: - Analytics

private extension MobileOnboardingSeedPhraseValidationViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(
            .walletSettingsRecoveryPhraseCheck,
            params: source.analyticsParams,
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Types

extension MobileOnboardingSeedPhraseValidationViewModel {
    enum State {
        case item(StateItem)
    }

    struct StateItem {
        let second: String
        let seventh: String
        let eleventh: String
    }
}
