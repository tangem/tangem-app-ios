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
        Analytics.log(.onrampButtonVerify)
        routable?.onProceedToWidget()
        dismiss()
    }

    func chooseAnotherMethod() {
        Analytics.log(.onrampButtonChooseAnotherMethod)
        routable?.onChooseAnother()
    }

    func close() {
        routable?.onClose()
        dismiss()
    }

    private func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
