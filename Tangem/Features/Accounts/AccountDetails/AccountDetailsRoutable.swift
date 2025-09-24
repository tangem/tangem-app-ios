//
//  AccountDetailsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol BaseEditableAccountDetailsRoutable: AnyObject {
    func editAccount()
}

protocol ArchivableAccountRoutable: AnyObject {
    func openArchiveAccountDialog(archiveAction: @escaping () throws -> Void)
}

protocol CryptoAccountDetailsRoutable: AnyObject {
    func manageTokens()
}
