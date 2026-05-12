//
//  OnrampKYCVerificationSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

class OnrampKYCVerificationSheetViewModel: FloatingSheetContentViewModel, ObservableObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    let providerName: String

    private let kycURL: URL?
    private weak var routable: (any OnrampKYCVerificationSheetRoutable)?

    init(
        providerName: String,
        kycURL: URL?,
        routable: any OnrampKYCVerificationSheetRoutable
    ) {
        self.providerName = providerName
        self.kycURL = kycURL
        self.routable = routable
    }

    func verify() {
        routable?.onrampKYCVerificationDidTapVerify(kycURL: kycURL)
        dismiss()
    }

    func chooseAnotherMethod() {
        routable?.onrampKYCVerificationDidTapChooseAnother()
        dismiss()
    }

    func close() {
        dismiss()
    }

    private func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
