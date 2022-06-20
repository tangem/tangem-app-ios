//
//  WalletConnectRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectRoutable: AnyObject {
    func openQRScanner(with codeBinding: Binding<String>)
}
