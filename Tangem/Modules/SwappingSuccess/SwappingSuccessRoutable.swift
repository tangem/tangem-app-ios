//
//  SwappingSuccessRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol SwappingSuccessRoutable: AnyObject {
    func openExplorer(url: URL?, currencyName: String)
    func didTapCloseButton()
}
