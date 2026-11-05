//
//  TangemPayBankingAccountAddressSigning.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol TangemPayBankingAccountAddressSigning {
    func signDepositAddress() async throws(TangemPayBankingAccountSigningError) -> TangemPayBankingAccountSigningResponse
}

public struct TangemPayBankingAccountSigningResponse {
    public let depositAddress: String
    public let signature: String
    public let derivationResult: [Data: DerivedKeys]

    public init(depositAddress: String, signature: String, derivationResult: [Data: DerivedKeys]) {
        self.depositAddress = depositAddress
        self.signature = signature
        self.derivationResult = derivationResult
    }
}

public struct TangemPayBankingAccountSigningError: Error {
    public let underlyingError: Error
    public let derivationResult: [Data: DerivedKeys]

    public init(underlyingError: Error, derivationResult: [Data: DerivedKeys]) {
        self.underlyingError = underlyingError
        self.derivationResult = derivationResult
    }

    public var isUserCancelled: Bool {
        (underlyingError as? TangemSdkError)?.isUserCancelled ?? (underlyingError is CancellationError)
    }
}
