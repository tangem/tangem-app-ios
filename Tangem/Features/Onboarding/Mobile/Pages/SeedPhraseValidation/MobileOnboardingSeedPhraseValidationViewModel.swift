//
//  MobileOnboardingSeedPhraseValidationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseValidationViewModel: ObservableObject {
    @Published var state: State?

    private let mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletId: UserWalletId
    private weak var delegate: MobileOnboardingSeedPhraseValidationDelegate?

    init(userWalletId: UserWalletId, delegate: MobileOnboardingSeedPhraseValidationDelegate) {
        self.userWalletId = userWalletId
        self.delegate = delegate
        setup()
    }
}

// MARK: - Internal methods

extension MobileOnboardingSeedPhraseValidationViewModel {
    func onAppear() {
        Analytics.log(.backupSeedCheckingScreenOpened, contextParams: .custom(.mobileWallet))
    }

    func onCreateWallet() {
        delegate?.didValidateSeedPhrase()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseValidationViewModel {
    func setup() {
        runTask(in: self) { viewModel in
            do {
                let context = try viewModel.mobileWalletSdk.validate(auth: .none, for: viewModel.userWalletId)
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
