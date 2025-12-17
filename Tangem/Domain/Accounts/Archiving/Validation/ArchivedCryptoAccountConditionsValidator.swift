//
//  ArchivedCryptoAccountConditionsValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

struct ArchivedCryptoAccountConditionsValidator {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId
    private let accountIdentifier: any AccountModelPersistentIdentifierConvertible
    private let accountModelPublisher: AnyPublisher<any CryptoAccountModel, Never>

    private var participatesInReferralProgram: Bool {
        get async throws {
            let referralProgramInfo = try await tangemApiService.loadReferralProgramInfo(
                for: userWalletId.stringValue,
                expectedAwardsLimit: ReferralConstants.expectedAwardsFetchLimit
            )

            guard let referralAddress = referralProgramInfo.referral?.address else {
                return false
            }

            let cryptoAccountModel = try await accountModelPublisher.async()

            // [REDACTED_TODO_COMMENT]
            return cryptoAccountModel
                .walletModelsManager
                .walletModels
                .flatMap(\.addresses)
                .contains { $0.value.caseInsensitiveEquals(to: referralAddress) }
        }
    }

    init(
        userWalletId: UserWalletId,
        accountIdentifier: any AccountModelPersistentIdentifierConvertible,
        accountModelPublisher: AnyPublisher<any CryptoAccountModel, Never>
    ) {
        self.userWalletId = userWalletId
        self.accountIdentifier = accountIdentifier
        self.accountModelPublisher = accountModelPublisher
    }
}

// MARK: - CryptoAccountConditionsValidator protocol conformance

extension ArchivedCryptoAccountConditionsValidator: CryptoAccountConditionsValidator {
    typealias ValidationError = AccountArchivationError

    func validate() async throws(ValidationError) {
        do {
            guard try await !participatesInReferralProgram else {
                // Account participates in an active referral program
                throw ValidationError.participatesInReferralProgram
            }
        } catch let error as ValidationError {
            throw error
        } catch {
            // Wrap unexpected errors (e.g., network errors)
            throw .unknownError(error)
        }
    }
}
