//
//  AppCoordinator+WalletConnectRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension AppCoordinator: WalletConnectRoutable {
    func openQRScanner(with codeBinding: Binding<String>) {
        qrScanViewModel = .init(code: codeBinding)
    }
}
