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
    private let card: TangemPayCard
    private let userWalletId: UserWalletId
    private weak var coordinator: TangemPayPinCheckRoutable?

    init(
        card: TangemPayCard,
        userWalletId: UserWalletId,
        coordinator: TangemPayPinCheckRoutable
    ) {
        self.card = card
        self.userWalletId = userWalletId
        self.coordinator = coordinator

        revealPin()

        Analytics.log(.visaScreenCurrentPinShown, contextParams: .userWallet(userWalletId))
    }

    func changePin() {
        Analytics.log(.visaScreenChangePinOnCurrentPinClicked, contextParams: .userWallet(userWalletId))
        coordinator?.closePinCheck()
        coordinator?.openTangemPaySetPin(card: card)
    }

    func close() {
        coordinator?.closePinCheck()
    }

    private func revealPin() {
        runTask(in: self) { viewModel in
            do {
                let pin = try await viewModel.card.getPin()

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
