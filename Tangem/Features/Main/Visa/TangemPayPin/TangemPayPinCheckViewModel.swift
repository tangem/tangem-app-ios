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

protocol TangemPayPinCheckRoutable: AnyObject {
    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount)
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
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayPinCheckRoutable?

    init(
        account: TangemPayAccount,
        coordinator: TangemPayPinCheckRoutable
    ) {
        self.coordinator = coordinator
        tangemPayAccount = account

        revealPin()
    }

    func changePin() {
        coordinator?.closePinCheck()
        coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
    }

    func close() {
        coordinator?.closePinCheck()
    }

    private func revealPin() {
        runTask { [self] in
            do {
                let pin = try await tangemPayAccount.getPin()
                state = .loaded(PIN: pin)
            } catch {
                onError()
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
