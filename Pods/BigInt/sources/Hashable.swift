//
//  Hashable.swift
//  BigInt
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2016-2017 Károly Lőrentey.
//

import SipHash

extension BigUInt: SipHashable {
    //MARK: Hashing

    /// Append this `BigUInt` to the specified hasher.
    public func appendHashes(to hasher: inout SipHasher) {
        for word in self.words {
            hasher.append(word)
        }
    }
}

extension BigInt: SipHashable {
    /// Append this `BigInt` to the specified hasher.
    public func appendHashes(to hasher: inout SipHasher) {
        hasher.append(sign)
        hasher.append(magnitude)
    }
}
