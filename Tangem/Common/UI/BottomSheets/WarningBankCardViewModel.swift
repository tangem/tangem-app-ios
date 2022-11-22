//
//  WarningBankCardViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class WarningBankCardViewModel: Identifiable {
    let confirmCallback: () -> ()
    let declineCallback: () -> ()

    init(confirmCallback: @escaping () -> (), declineCallback: @escaping () -> ()) {
        self.confirmCallback = confirmCallback
        self.declineCallback = declineCallback
    }

    func onAppear() {
        Analytics.log(.p2PScreenOpened)
    }
}
