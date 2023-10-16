//
//  WeakifyFuncion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

func weakify<Owner: AnyObject>(_ owner: Owner, forFunction builder: @escaping (Owner) -> () -> Void) -> () -> Void {
    return { [weak owner] in
        if let owner = owner {
            builder(owner)()
        }
    }
}

func weakify<Owner: AnyObject, Param>(_ owner: Owner, forFunction builder: @escaping (Owner) -> (Param) -> Void) -> (Param) -> Void {
    return { [weak owner] param in
        if let owner = owner {
            builder(owner)(param)
        }
    }
}
