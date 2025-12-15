//
//  TangemPayFailedToIssueCardRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol TangemPayFailedToIssueCardRoutable: AnyObject {
    func closeFailedToIssueCardSheet()
    func openMailFromFailedToIssueCardSheet(mailViewModel: MailViewModel)
}
