//
//  OnrampProviderRequirementsBottomSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class OnrampProviderRequirementsBottomSheetViewModel: FloatingSheetContentViewModel, ObservableObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    func close() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}
