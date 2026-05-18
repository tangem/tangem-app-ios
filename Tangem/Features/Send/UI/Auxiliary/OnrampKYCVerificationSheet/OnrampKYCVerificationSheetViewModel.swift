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

    private weak var routable: (any OnrampKYCVerificationSheetRoutable)?

    init(
        providerName: String,
        routable: any OnrampKYCVerificationSheetRoutable
    ) {
        self.providerName = providerName
        self.routable = routable
    }

    func verify() {
        routable?.onProceedToWidget()
        dismiss()
    }

    func chooseAnotherMethod() {
        routable?.onChooseAnother()
        dismiss()
    }

    func close() {
        dismiss()
    }

    private func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
