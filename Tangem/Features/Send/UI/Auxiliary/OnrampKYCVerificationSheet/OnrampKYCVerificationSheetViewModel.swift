//
//  OnrampKYCVerificationSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
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
        ExpressLogger.tag("Onramp").info("[KYCSheetVM.verify] entry routable=\(routable == nil ? "nil" : "set")")
        routable?.onProceedToWidget()
        ExpressLogger.tag("Onramp").info("[KYCSheetVM.verify] onProceedToWidget returned; calling dismiss")
        dismiss()
    }

    func chooseAnotherMethod() {
        ExpressLogger.tag("Onramp").info("[KYCSheetVM.chooseAnotherMethod] entry routable=\(routable == nil ? "nil" : "set")")
        routable?.onChooseAnother()
    }

    func close() {
        ExpressLogger.tag("Onramp").info("[KYCSheetVM.close] entry routable=\(routable == nil ? "nil" : "set")")
        routable?.onClose()
        dismiss()
    }

    private func dismiss() {
        ExpressLogger.tag("Onramp").info("[KYCSheetVM.dismiss] scheduling removeActiveSheet")
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
