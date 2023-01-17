//
//  WarningBankCardViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class WarningBankCardViewModel: Identifiable {
    let confirmCallback: () -> Void
    let declineCallback: () -> Void

    init(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void) {
        self.confirmCallback = confirmCallback
        self.declineCallback = declineCallback
    }

    func onAppear() {
        Analytics.log(.p2PScreenOpened)
    }
}
