//
//  UserWalletStorageAgreementRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletStorageAgreementRoutable: AnyObject {
    func didAgreeToSaveUserWallets()
    func didDeclineToSaveUserWallets()
}
