//
//  MobileMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

class MobileMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subtitleSubject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    let containsSensitiveInfo: Bool = false

    private let subtitleSubject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)

    private let isUserWalletLocked: Bool
    private let updatePublisher: AnyPublisher<UpdateResult, Never>

    private var updateSubscription: AnyCancellable?

    init(isUserWalletLocked: Bool, isBackupNeeded: Bool, updatePublisher: AnyPublisher<UpdateResult, Never>) {
        self.updatePublisher = updatePublisher
        self.isUserWalletLocked = isUserWalletLocked
        setupSubtitle(isBackupNeeded: isBackupNeeded)
        bind()
    }
}

// MARK: - Private methods

private extension MobileMainHeaderSubtitleProvider {
    func bind() {
        updateSubscription = updatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { provider, event in
                if case .configurationChanged(let model) = event {
                    let isBackupNeeded = model.config.hasFeature(.mnemonicBackup) && model.config.hasFeature(.iCloudBackup)
                    provider.setupSubtitle(isBackupNeeded: isBackupNeeded)
                }
            }
    }

    func setupSubtitle(isBackupNeeded: Bool) {
        var subtitle = [Localization.hwMobileWallet]

        if isUserWalletLocked {
            subtitle.append(Localization.commonLocked)
        } else if isBackupNeeded {
            subtitle.append(Localization.hwBackupNoBackup)
        }

        subtitleSubject.send(.init(messages: subtitle, formattingOption: .default))
    }
}
