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

    var connectionTargetKind: WCTransactionConnectionTargetKind? {
        displayModel.connectionTargetKind
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

    var confirmTransactionPolicy: ConfirmTransactionPolicy {
        displayModel.confirmTransactionPolicy
    }

    private var isDataReady: Bool {
        displayModel.isDataReady
    }
}
