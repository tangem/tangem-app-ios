//
//  MobileOnboardingSeedPhraseRecoveryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseRecoveryViewModel: ObservableObject {
    @Published var state: State?

    let continueButtonTitle = Localization.commonContinue
    let responsibilityDescription = Localization.backupSeedResponsibility

    private let mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletId: UserWalletId
    private weak var delegate: MobileOnboardingSeedPhraseRecoveryDelegate?

    init(userWalletId: UserWalletId, delegate: MobileOnboardingSeedPhraseRecoveryDelegate) {
        self.userWalletId = userWalletId
        self.delegate = delegate
        setup()
    }
}

extension MobileOnboardingSeedPhraseRecoveryViewModel {
    func onContinueTap() {
        delegate?.seedPhraseRecoveryContinue()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseRecoveryViewModel {
    func setup() {
        runTask(in: self) { viewModel in
            do {
                let context = try viewModel.mobileWalletSdk.validate(auth: .none, for: viewModel.userWalletId)
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
