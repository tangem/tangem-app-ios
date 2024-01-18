//
//  VisaWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol VisaWalletMainHeaderSubtitleDataSource: AnyObject {
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> { get }
    var fiatBalance: String { get }
    var blockchainName: String { get }
}

class VisaWalletMainHeaderSubtitleProvider {
    private weak var dataSource: VisaWalletMainHeaderSubtitleDataSource?

    private let isLoadingSubject: CurrentValueSubject<Bool, Never>
    private let subtitleSubject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let isUserWalletLocked: Bool

    private var stateUpdateSubscription: AnyCancellable?

    init(isUserWalletLocked: Bool, dataSource: VisaWalletMainHeaderSubtitleDataSource?) {
        self.isUserWalletLocked = isUserWalletLocked
        self.dataSource = dataSource

        isLoadingSubject = .init(!isUserWalletLocked)

        initialSetup()
    }

    private func initialSetup() {
        if isUserWalletLocked {
            displayLockedWalletMessage()
        } else {
            bind()
        }
    }

    private func bind() {
        stateUpdateSubscription = dataSource?.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newState in
                guard let self else { return }

                if newState == .created || newState == .loading {
                    return
                }

                isLoadingSubject.send(false)

                switch newState {
                case .failed:
                    formatErrorMessage()
                case .idle, .noAccount:
                    formatBalanceMessage()
                case .created, .loading, .noDerivation:
                    break
                }
            })
    }

    private func formatBalanceMessage() {
        guard let dataSource else { return }

        let balance = dataSource.fiatBalance
        subtitleSubject.send(.init(messages: [balance, dataSource.blockchainName], formattingOption: .default))
    }

    private func formatErrorMessage() {
        subtitleSubject.send(.init(messages: [BalanceFormatter.defaultEmptyBalanceString], formattingOption: .default))
    }

    private func displayLockedWalletMessage() {
        subtitleSubject.send(.init(messages: [Localization.commonLocked], formattingOption: .default))
    }
}

extension VisaWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subtitleSubject.eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { true }
}

extension WalletModel: VisaWalletMainHeaderSubtitleDataSource {
    var blockchainName: String {
        "Polygon PoS"
    }
}
