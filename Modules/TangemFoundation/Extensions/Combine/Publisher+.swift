//
//  Publisher+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Publisher {
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }

    func withWeakCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.CompactMap<Self, (Object, Self.Output)> where Object: AnyObject {
        return compactMap { [weak object] output in
            guard let object = object else { return nil }

            return (object, output)
        }
    }

    func withUnownedCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.Map<Self, (Object, Self.Output)> where Object: AnyObject {
        return map { [unowned object] output in
            return (object, output)
        }
    }
}
