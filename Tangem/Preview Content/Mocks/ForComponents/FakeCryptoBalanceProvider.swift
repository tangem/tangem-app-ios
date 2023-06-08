//
//  FakeCryptoBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTokenBalanceProvider: BalanceProvider, ActionButtonsProvider {
    private let buttons: [ButtonWithIconInfo]
    private let delay: TimeInterval
    private let cryptoBalanceInfo: BalanceInfo

    private let valueSubject = CurrentValueSubject<LoadingValue<BalanceInfo>, Never>(.loading)
    private let buttonsSubject: CurrentValueSubject<[ButtonWithIconInfo], Never>

    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> {
        scheduleSendingValue()
        return valueSubject.eraseToAnyPublisher()
    }

    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { buttonsSubject.eraseToAnyPublisher() }

    init(buttons: [ButtonWithIconInfo], delay: TimeInterval, cryptoBalanceInfo: BalanceInfo) {
        self.buttons = buttons
        buttonsSubject = .init(buttons)
        self.delay = delay
        self.cryptoBalanceInfo = cryptoBalanceInfo
    }

    private func scheduleSendingValue() {
        guard delay > 0 else {
            sendInfo()
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            self.sendInfo()
        }
    }

    private func sendInfo() {
        if self.cryptoBalanceInfo.balance == -1 {
            self.valueSubject.send(.failedToLoad(error: "Failed to load balance. Network unreachable"))
            self.buttonsSubject.send(self.disabledButtons())
        } else {
            self.valueSubject.send(.loaded(self.cryptoBalanceInfo))
        }
    }

    private func disabledButtons() -> [ButtonWithIconInfo] {
        buttons.map { button in
            .init(title: button.title, icon: button.icon, action: button.action, disabled: true)
        }
    }
}
