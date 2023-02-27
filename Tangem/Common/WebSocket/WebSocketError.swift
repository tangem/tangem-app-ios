//
//  WebSocketError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum WebSocketError: Error {
    case closedUnexpectedly
    case peerDisconnected
}
