//
//  KeysDerivingProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol KeysDerivingProvider: AnyObject {
    var keysDerivingInteractor: KeysDeriving { get }
}
