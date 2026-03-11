//
//  ApproveRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ApproveRoutable: AnyObject {
    func didSendApproveTransaction()
    func userDidCancel()
    func openLearnMore()
}
