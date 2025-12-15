//
//  MultiWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine

protocol MultiWalletMainHeaderSubtitleDataSource: AnyObject {
    var cardSetLabel: String { get }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { get }
    var hasImportedWallets: Bool { get }
}

class MultiWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subtitleInfoSubject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var containsSensitiveInfo: Bool { false }

    private var suffix: String? {
        if isUserWalletLocked {
            return Localization.commonLocked
        }

        if dataSource.hasImportedWallets {
            return Localization.commonSeedPhrase
        }

        return nil
    }

    private let subtitleInfoSubject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let isUserWalletLocked: Bool

    private unowned var dataSource: MultiWalletMainHeaderSubtitleDataSource
    private var updateSubscription: AnyCancellable?

    init(
        isUserWalletLocked: Bool,
        dataSource: MultiWalletMainHeaderSubtitleDataSource
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.dataSource = dataSource

        subscribeToUpdates()
        formatSubtitle()
    }

    private func subscribeToUpdates() {
        updateSubscription = dataSource.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                switch value {
                case .configurationChanged:
                    self?.formatSubtitle()
                default:
                    break
                }
            })
    }

    private func formatSubtitle() {
        var subtitle = [dataSource.cardSetLabel]
        if let suffix {
            subtitle.append(suffix)
        }
        subtitleInfoSubject.send(.init(messages: subtitle, formattingOption: .default))
    }
}
