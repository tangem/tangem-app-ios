//
//  SingleWalletMainHeaderSubtitleProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SingleWalletMainHeaderSubtitleDataSource: AnyObject {
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> { get }
    var balance: String { get }
}

class SingleWalletMainHeaderSubtitleProvider: MainHeaderSubtitleProvider {
    private weak var dataSource: SingleWalletMainHeaderSubtitleDataSource?

    private let subject: CurrentValueSubject<MainHeaderSubtitleInfo, Never> = .init(.empty)
    private let isLoadingSubject: CurrentValueSubject<Bool, Never>
    private let isUserWalletLocked: Bool

    private var stateUpdateSubscription: AnyCancellable?

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { true }

    init(isUserWalletLocked: Bool, dataSource: SingleWalletMainHeaderSubtitleDataSource?) {
        self.isUserWalletLocked = isUserWalletLocked
        self.dataSource = dataSource
        isLoadingSubject = .init(!isUserWalletLocked)
        bind()
    }

    private func bind() {
        if isUserWalletLocked {
            displayLockedWalletMessage()
            return
        }

        stateUpdateSubscription = dataSource?.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newState in
                guard let self else { return }

                if newState == .created || newState == .loading {
                    return
                }

                isLoadingSubject.send(false)

                switch newState {
                case .failed(let error):
                    formatErrorMessage(with: error)
                case .noAccount(let message):
                    formatErrorMessage(with: message)
                case .idle:
                    formatBalanceMessage()
                case .created, .loading, .noDerivation:
                    break
                }
            })
    }

    private func formatBalanceMessage() {
        guard let dataSource else { return }

        let balance = dataSource.balance
        subject.send(.init(message: balance, formattingOption: .default))
    }

    private func formatErrorMessage(with text: String) {
        subject.send(.init(message: text, formattingOption: .error))
    }

    private func displayLockedWalletMessage() {
        subject.send(.init(message: Localization.commonLocked, formattingOption: .default))
    }
}

extension WalletModel: SingleWalletMainHeaderSubtitleDataSource {}
