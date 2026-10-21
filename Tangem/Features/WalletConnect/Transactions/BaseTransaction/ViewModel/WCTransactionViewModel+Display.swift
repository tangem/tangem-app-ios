//
//  WCTransactionViewModel+Display.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

extension WCTransactionViewModel {
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

    var signingActionButtonType: SigningActionButtonViewType {
        displayModel.signingActionButtonType
    }
}
