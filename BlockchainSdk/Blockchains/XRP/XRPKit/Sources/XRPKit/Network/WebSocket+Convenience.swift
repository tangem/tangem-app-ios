//
//  File.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

#if !os(Linux)

import Foundation

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension WebSocket {
    func subscribe(account: String) {
        let parameters: [String: Any] = [
            "id": UUID().uuidString,
            "command": "subscribe",
            "accounts": [account],
        ]
        let data = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        send(data: data)
    }
}

#endif
