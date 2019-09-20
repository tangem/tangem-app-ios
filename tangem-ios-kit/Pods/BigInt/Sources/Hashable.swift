//
//  Hashable.swift
//  BigInt
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2016-2017 Károly Lőrentey.
//

extension BigUInt: Hashable {
    //MARK: Hashing

    /// Append this `BigUInt` to the specified hasher.
    public func hash(into hasher: inout Hasher) {
        for word in self.words {
            hasher.combine(word)
        }
    }
}

extension BigInt: Hashable {
    /// Append this `BigInt` to the specified hasher.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sign)
        hasher.combine(magnitude)
    }
}
