//
//  TangemPayPinCheckViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemVisa
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemPay

protocol TangemPayPinCheckRoutable: AnyObject {
    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount)
    func openTangemPaySetPin(card: TangemPayCard)
    func closePinCheck()
}

final class TangemPayPinCheckViewModel: ObservableObject, Identifiable {
    enum State {
        case loading
        case loaded(PIN: String)
    }

    @Published var state: State = .loading

    var pinCodeLength: Int {
        pinValidator.pinCodeLength
    }

    private let pinValidator = VisaPinValidator()
    /// Exactly one of `card` / `tangemPayAccount` is set — `card` in the multi-card flow,
    /// `tangemPayAccount` in the legacy single-card flow.
    private let card: TangemPayCard?
    private let tangemPayAccount: TangemPayAccount?
    private let userWalletId: UserWalletId
    private weak var coordinator: TangemPayPinCheckRoutable?

    init(
        account: TangemPayAccount,
        coordinator: TangemPayPinCheckRoutable
    ) {
        card = nil
        tangemPayAccount = account
        userWalletId = account.userWalletId
        self.coordinator = coordinator

        revealPin()

        Analytics.log(.visaScreenCurrentPinShown, contextParams: .userWallet(userWalletId))
    }

    init(
        card: TangemPayCard,
        userWalletId: UserWalletId,
        coordinator: TangemPayPinCheckRoutable
    ) {
        self.card = card
        tangemPayAccount = nil
        self.userWalletId = userWalletId
        self.coordinator = coordinator

        revealPin()

        Analytics.log(.visaScreenCurrentPinShown, contextParams: .userWallet(userWalletId))
    }

    func changePin() {
        Analytics.log(.visaScreenChangePinOnCurrentPinClicked, contextParams: .userWallet(userWalletId))
        coordinator?.closePinCheck()
        if let card {
            coordinator?.openTangemPaySetPin(card: card)
        } else if let tangemPayAccount {
            coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
        }
    }

    func close() {
        coordinator?.closePinCheck()
    }

    private func revealPin() {
        runTask(in: self) { viewModel in
            do {
                let pin: String
                if let card = viewModel.card {
                    pin = try await card.getPin()
                } else if let tangemPayAccount = viewModel.tangemPayAccount {
                    pin = try await tangemPayAccount.getPin()
                } else {
                    viewModel.onError()
                    return
                }

                Task { @MainActor in
                    viewModel.state = .loaded(PIN: pin)
                }
            } catch {
                viewModel.onError()
            }
        }
    }

    private func onError() {
        coordinator?.closePinCheck()
        Task { @MainActor in
            Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
                .present(
                    layout: .top(padding: 20),
                    type: .temporary()
                )
        }
    }
}

extension TangemPayPinCheckViewModel: FloatingSheetContentViewModel {}
