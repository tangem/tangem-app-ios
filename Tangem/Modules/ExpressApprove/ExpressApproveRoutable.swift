//
//  ExpressApproveRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol ExpressApproveRoutable: AnyObject {
    func didSendApproveTransaction()
    func userDidCancel()
}
