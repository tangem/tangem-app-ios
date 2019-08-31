//
//  PublicKey.swift
//  web3swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 The Matter Inc. All rights reserved.
//

import Foundation

public struct PublicKey {
    public let x: String
    public let y: String
    
    public func getComponentsWithoutPrefix() -> PublicKey {
        var x = self.x
        var y = self.y
        if x.hasHexPrefix() {
            x.removeFirst(2)
        }
        if y.hasHexPrefix() {
            y.removeFirst(2)
        }
        return PublicKey(x: x, y: y)
    }
}
