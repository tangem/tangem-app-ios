//
//  AsyncOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

open class GBAsyncBlockOperation: GBAsyncOperation {

    let block: () -> Void

    public init(block: @escaping () -> Void) {
        self.block = block
    }

    open override func main() {
        block()
        finish()
    }
}
