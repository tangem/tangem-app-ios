//
//  TransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol TransactionValidator: WalletProvider {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws
    func validate(amount: Amount, fee: Fee) throws

    func validate(transaction: Transaction) async throws
}

public enum DestinationType: Hashable {
    /// The specified address will be used for verification
    case address(String)
}

// MARK: - Default implementation

public extension TransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validateAmounts(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
    }

    /// Validation will be doing with `amount`, `fee` and `destinationAddress`  from the `Transaction`
    func validate(transaction: Transaction) async throws {
        try await validate(amount: transaction.amount, fee: transaction.fee, destination: .address(transaction.destinationAddress))
    }
}

// MARK: - Simple sending amount validation (Amount, Fee)

public extension TransactionValidator {
    /// Method for the sending amount and fee validation
    /// Has default implementation just for checking balance and numbers
    func validateAmounts(amount: Amount, fee: Fee) throws {
        // Is fee currency sending or not
        let isFeeCurrency = amount.type == fee.amount.type

        switch amount.type.token?.metadata.kind {
        case .fungible, .none:
            try validate(amount: amount)
            try validate(fee: fee, isFeeCurrency: isFeeCurrency)
            try validateTotal(amount: amount, fee: fee.amount)

        case .nonFungible:
            // We can't validate amounts for non-fungible tokens, therefore performing only the fee validation
            try validate(fee: fee, isFeeCurrency: isFeeCurrency)
        }
    }

    func validate(amount: Amount) throws {
        guard amount.value >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        guard balance >= amount else {
            throw ValidationError.amountExceedsBalance
        }
    }

    func validate(fee: Fee, isFeeCurrency: Bool) throws {
        guard fee.amount.value >= 0 else {
            throw ValidationError.invalidFee
        }

        guard let feeBalance = wallet.amounts[fee.amount.type] else {
            throw ValidationError.balanceNotFound
        }

        guard feeBalance >= fee.amount else {
            throw ValidationError.feeExceedsBalance(fee, blockchain: wallet.blockchain, isFeeCurrency: isFeeCurrency)
        }
    }

    func validateTotal(amount: Amount, fee: Amount) throws {
        // If we try to spend all amount from coin
        guard amount.type == fee.type else {
            // Safely return because all the checks were above
            return
        }

        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }

        let total = amount + fee

        guard balance >= total else {
            throw ValidationError.totalExceedsBalance
        }
    }
}

// MARK: - DustRestrictable

extension TransactionValidator where Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateDust(amount: amount, fee: fee.amount)
    }
}

// MARK: - MinimumBalanceRestrictable

extension TransactionValidator where Self: MinimumBalanceRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateMinimumBalance(amount: amount, fee: fee.amount)
    }
}

// MARK: - MaximumAmountRestrictable

extension TransactionValidator where Self: MaximumAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateMaximumAmount(amount: amount, fee: fee.amount)
    }
}

// MARK: - MinimumAmountRestrictable

extension TransactionValidator where Self: MinimumAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateMinimumRestrictAmount(amount: amount, fee: fee.amount)
    }
}

// MARK: - DustRestrictable, MaximumAmountRestrictable e.g. KaspaWalletManager

extension TransactionValidator where Self: MaximumAmountRestrictable, Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateDust(amount: amount, fee: fee.amount)
        try validateMaximumAmount(amount: amount, fee: fee.amount)
    }
}

// MARK: - DustRestrictable, CardanoTransferRestrictable e.g. CardanoWalletManager

extension TransactionValidator where Self: DustRestrictable, Self: CardanoTransferRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee)
        try validateCardanoTransfer(amount: amount, fee: fee)
        try validateDust(amount: amount, fee: fee.amount)
    }
}

// MARK: - ReserveAmountRestrictable

extension TransactionValidator where Self: ReserveAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validateAmounts(amount: amount, fee: fee)

        switch destination {
        case .address(let address):
            try await validateReserveAmount(amount: amount, address: address)
        }
    }
}

// MARK: - RequiredMemoRestrictable & ReserveAmountRestrictable e.g. XRPWalletManager

extension TransactionValidator where Self: RequiredMemoRestrictable, Self: ReserveAmountRestrictable {
    func validate(transaction: Transaction) async throws {
        try validateAmounts(amount: transaction.amount, fee: transaction.fee)
        try await validateReserveAmount(amount: transaction.amount, address: transaction.destinationAddress)
        try await validateRequiredMemo(destination: transaction.destinationAddress, transactionParams: transaction.params)
    }
}

// MARK: - FeeResourceRestrictable

extension TransactionValidator where Self: FeeResourceRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        BSDKLogger.debug("TransactionValidator \(self) doesn't check destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validate(amount: amount)
        try validateFeeResource(amount: amount, fee: fee.amount)
    }
}

// MARK: - RentExtemptionRestrictable e.g. SolanaWalletManager

extension TransactionValidator where Self: RentExtemptionRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try validate(amount: amount, fee: fee)
        try await validateDestinationForRentExemption(amount: amount, fee: fee, destination: destination)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validate(amount: amount, fee: fee)
        try validateRentExemption(amount: amount, fee: fee.amount)
    }
}
