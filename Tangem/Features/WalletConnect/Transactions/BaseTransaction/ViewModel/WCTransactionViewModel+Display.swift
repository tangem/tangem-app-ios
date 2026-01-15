//
//  WCTransactionViewModel+Display.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension WCTransactionViewModel {
    var userWalletName: String {
        displayModel.userWalletName
    }

    var isWalletRowVisible: Bool {
        displayModel.isWalletRowVisible
    }

    var primariActionButtonTitle: String {
        displayModel.primaryActionButtonTitle
    }

    var isActionButtonBlocked: Bool {
        displayModel.isActionButtonBlocked
    }

    var simulationDisplayModel: WCTransactionSimulationDisplayModel? {
        displayModel.simulationDisplayModel
    }

    var tangemIconProvider: TangemIconProvider {
        displayModel.tangemIconProvider
    }

    private var isDataReady: Bool {
        displayModel.isDataReady
    }
}
