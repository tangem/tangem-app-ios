//
//  LendingWithdrawText.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
enum LendingWithdrawText {
    static let title = "Withdrawal"
    static let source = "Lending on Aave"
    static let withdraw = "Withdraw"
    static let notice = "Your funds will be available for use immediately after withdrawal."
    static let failure = "We couldn't complete your withdrawal. Your funds are safe and still earning on Aave. Please try again later."

    static func availableBalance(_ balance: String) -> String {
        "Available balance: \(balance)"
    }

    static func notEnough(_ currencySymbol: String) -> String {
        "Not enough \(currencySymbol)"
    }
}
