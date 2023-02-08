//
//  OrderedWeakObjectsCollection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Use this class for saving a strong objects as weak
public class OrderedWeakObjectsCollection<T> {
    private typealias KeyType = NSNumber
    private let mapTable: NSMapTable<KeyType, AnyObject> = NSMapTable.strongToWeakObjects()

    private var allKeys: [KeyType] {
        mapTable.keyEnumerator().compactMap { $0 as? KeyType }
    }

    public init() {}

    public func add(_ delegate: T) {
        let freeKey = NSNumber(value: allKeys.map { $0.intValue }.max().map { $0 + 1 } ?? 0)
        mapTable.setObject(delegate as AnyObject, forKey: freeKey)
    }

    public func remove(_ delegateToRemove: T) {
        if let key = mapTable.keyEnumerator()
            .first(where: { mapTable.object(forKey: $0 as? KeyType) === delegateToRemove as AnyObject }) as? KeyType {
            mapTable.removeObject(forKey: key)
        }
    }

    public func contains(_ delegate: T) -> Bool {
        return mapTable.keyEnumerator()
            .first(where: { mapTable.object(forKey: $0 as? KeyType) === delegate as AnyObject }) as? KeyType != nil
    }

    public var allDelegates: [T] {
        allKeys
            .map { key -> (Int, T?) in
                (key.intValue, mapTable.object(forKey: key) as? T)
            }
            .sorted { first, second -> Bool in
                let (firstKey, _) = first
                let (secondKey, _) = second

                return firstKey < secondKey
            }
            .compactMap { _, value -> T? in
                value
            }
    }
}
