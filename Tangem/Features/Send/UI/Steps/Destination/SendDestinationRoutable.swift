//
//  SendDestinationRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendDestinationRoutable: AnyObject {
    func openQRScanner(output: QRScannerOutput, networkName: String)
}

protocol SendDestinationStepRoutable: AnyObject {
    func destinationStepFulfilled()
}
