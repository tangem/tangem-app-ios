//
//  TokenFeeLoaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Everything a fee is calculated with for one sending token, so that the way it is priced is decided in one place.
protocol TokenFeeLoaderProvider {
    func makeMainTokenFeeLoader() -> TokenFeeLoader
    /// `nil` when the gasless dependency this token needs is missing, which is a wiring error rather than
    /// a supported outcome. A `feeToken` that turns out to be unusable surfaces as a fee error from the loader.
    func makeGaslessTokenFeeLoader(feeToken: BSDKToken, yieldFeeContext: GaslessYieldFeeContext?) -> TokenFeeLoader?
    /// `nil` when the fee is not editable by hand.
    func makeCustomFeeProvider() -> (any CustomFeeProvider)?
}
