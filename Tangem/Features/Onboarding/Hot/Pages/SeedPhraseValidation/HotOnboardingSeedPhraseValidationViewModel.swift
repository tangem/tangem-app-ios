//
//  HotOnboardingSeedPhraseValidationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemHotSdk

final class HotOnboardingSeedPhraseValidationViewModel: ObservableObject {
    @Published var state: State?

    private let hotSdk: HotSdk = CommonHotSdk()

    private let userWalletId: UserWalletId
    private weak var delegate: HotOnboardingSeedPhraseValidationDelegate?

    init(userWalletId: UserWalletId, delegate: HotOnboardingSeedPhraseValidationDelegate) {
        self.userWalletId = userWalletId
        self.delegate = delegate
        setup()
    }
}

// MARK: - Internal methods

extension HotOnboardingSeedPhraseValidationViewModel {
    func onCreateWallet() {
        delegate?.didValidateSeedPhrase()
    }
}

// MARK: - Private methods

private extension HotOnboardingSeedPhraseValidationViewModel {
    func setup() {
        runTask(in: self) { viewModel in
            do {
                let context = try viewModel.hotSdk.validate(auth: .none, for: viewModel.userWalletId)
                let mnemonic = try viewModel.hotSdk.exportMnemonic(context: context)
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

extension HotOnboardingSeedPhraseValidationViewModel {
    enum State {
        case item(StateItem)
    }

    struct StateItem {
        let second: String
        let seventh: String
        let eleventh: String
    }
}
