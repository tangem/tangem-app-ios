//
//  MobileOnboardingSeedPhraseRevealViewModel.swift
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

final class MobileOnboardingSeedPhraseRevealViewModel: ObservableObject {
    @Published var state: State?
    @Published var alert: AlertBinder?

    private let mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let context: MobileWalletContext

    var bag: Set<AnyCancellable> = []

    init(context: MobileWalletContext) {
        self.context = context
        bind()
        setup()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseRevealViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingSeedScreenshotAlert)
                Analytics.log(.onboardingSeedScreenCapture, contextParams: .custom(.mobileWallet))
            }
            .store(in: &bag)
    }

    func setup() {
        runTask(in: self) { viewModel in
            do {
                let mnemonic = try viewModel.mobileWalletSdk.exportMnemonic(context: viewModel.context)
                await viewModel.setupState(mnemonic: mnemonic)
            } catch {
                AppLogger.error("Export mnemonic to reveal failed:", error: error)
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
            description: Localization.backupSeedCaution(mnemonic.count)
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

extension MobileOnboardingSeedPhraseRevealViewModel {
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
