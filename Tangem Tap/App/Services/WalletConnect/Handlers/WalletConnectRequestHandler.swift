//
//  WalletConnectRequestHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol TangemWalletConnectRequestHandler: RequestHandler {
    var delegate: WalletConnectHandlerDelegate? { get }
    var dataSource: WalletConnectHandlerDataSource? { get }
}
