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

        Analytics.log(.visaScreenCurrentPinShown)
    }

    func changePin() {
        Analytics.log(.visaScreenChangePinOnCurrentPinClicked)
        coordinator?.closePinCheck()
        coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
    }

    func close() {
        coordinator?.closePinCheck()
    }

    private func revealPin() {
        runTask(in: self) { viewModel in
            do {
                let service = viewModel.tangemPayAccount
                    .customerInfoManagementService

                let publicKey = try await RainCryptoUtilities
                    .getRainRSAPublicKey(
                        for: FeatureStorage.instance.visaAPIType
                    )

                let (secretKey, sessionId) = try RainCryptoUtilities
                    .generateSecretKeyAndSessionId(
                        publicKey: publicKey
                    )
                let response = try await service.getPin(
                    sessionId: sessionId
                )
                let decryptedBlock = try RainCryptoUtilities.decryptSecret(
                    base64Secret: response.secret,
                    base64Iv: response.iv,
                    secretKey: secretKey
                )
                let decryptedPin = try RainCryptoUtilities.decryptPinBlock(
                    encryptedBlock: decryptedBlock
                )

                Task { @MainActor in
                    viewModel.state = .loaded(PIN: decryptedPin)
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
