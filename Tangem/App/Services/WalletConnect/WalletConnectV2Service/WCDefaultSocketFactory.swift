//
//  DefaultWCSocketFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2

struct WCDefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        WebSocket(url: url)
    }
}

extension WebSocket: WebSocketConnecting { }
