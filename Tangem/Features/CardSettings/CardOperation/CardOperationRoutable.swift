//
//  CardOperationRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CardOperationRoutable: AnyObject {
    func popToRoot()
    func dismissCardOperation()
}
