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
    let providerImageURL: URL?

    private let kycURL: URL?
    private let onVerify: (URL?) -> Void
    private let onChooseAnother: () -> Void

    init(
        providerName: String,
        providerImageURL: URL?,
        kycURL: URL?,
        onVerify: @escaping (URL?) -> Void,
        onChooseAnother: @escaping () -> Void
    ) {
        self.providerName = providerName
        self.providerImageURL = providerImageURL
        self.kycURL = kycURL
        self.onVerify = onVerify
        self.onChooseAnother = onChooseAnother
    }

    func verify() {
        onVerify(kycURL)
        dismiss()
    }

    func chooseAnotherMethod() {
        onChooseAnother()
        dismiss()
    }

    func close() {
        dismiss()
    }

    private func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
