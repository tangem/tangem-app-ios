//
//  WalletConnectRequestHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol TangemWalletConnectRequestHandler: RequestHandler {
    var action: WalletConnectAction { get }
    var delegate: WalletConnectHandlerDelegate? { get }
    var dataSource: WalletConnectHandlerDataSource? { get }
}

extension TangemWalletConnectRequestHandler {
    func canHandle(request: Request) -> Bool {
        action.rawValue == request.method
    }
}
