//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

protocol ExpressRoutable: AnyObject {
    func presentFeeSelectorView()
    func presentSwappingTokenList(sourceCurrency: Currency)
    func presentSuccessView(inputModel: SwappingSuccessInputModel)
    func presentApproveView()
}
