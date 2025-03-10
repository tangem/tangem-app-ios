//
//  UniversalErrorCodeBuilder.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct UniversalErrorCodeBuilder {
    public static let unknownErrorCode = -1
    private let feature: Feature

    public init(for feature: Feature) {
        self.feature = feature
    }

    /// Generates an error code as an Int in the format xxxyyzzz.
    /// - Parameters:
    ///   - errorCodeInfo: Info about error. The `subsystemCode` must be in rage 0-99, `errorCode` must be in rage (0-999)..
    /// - Returns: An Int like 10102042 (feature=101, subsystem=2, error=42). `-1` if codes didn't fall in specified ranges
    public func makeUniversalErrorCode(errorCodeInfo: Info) -> Int {
        let subsystemCode = abs(errorCodeInfo.subsystemCode)
        let errorCode = abs(errorCodeInfo.errorCode)

        return makeUniversalErrorCode(subsystemCode: subsystemCode, errorCode: errorCode)
    }

    /// Generates an error code as an Int in the format xxxyyzzz.
    /// - Parameters:
    ///   - subsystem: The subsystem code (yy, 0-99).
    ///   - errorCode: The specific error code (zzz, 0-999).
    /// - Returns: An Int like 10102042 (feature=101, subsystem=2, error=42). `-1` if codes didn't fall in specified ranges
    public func makeUniversalErrorCode(subsystemCode: Int, errorCode: Int) -> Int {
        guard
            (0 ... 99).contains(subsystemCode),
            (0 ... 999).contains(errorCode)
        else {
            return -1
        }

        return feature.errorCodeBase + subsystemCode * 1000 + errorCode
    }

    /// Generates an error code as an Int in the format xxxyyzzz. Where xxx - Feature code, yy - subsystem code and zzz - error code.
    /// - Returns: If error is `TangemError` the universal error code will be generated, if not - `-1` will be returned
    public func makeUniversalErrorCode(error: Error) -> Int {
        guard let tangemError = error as? TangemError else {
            return Self.unknownErrorCode
        }

        return makeUniversalErrorCode(subsystemCode: tangemError.subsystemCode, errorCode: tangemError.errorCode)
    }

    /// Generates an error code as an Int in the format xxxyyzzz. Where xxx - Feature code, yy - subsystem code and zzz - error code.
    /// - Parameters:
    ///   - toSubsystemErrorCode: this must be 5 digits value. Prefix with feature code will be added to the result.
    public func prependFeatureCode(toSubsystemErrorCode code: Int) -> Int {
        guard (0 ... 100000).contains(code) else {
            return -1
        }
        return feature.errorCodeBase + code
    }
}

public extension UniversalErrorCodeBuilder {
    struct Info {
        let subsystemCode: Int
        let errorCode: Int

        public init(subsystemCode: Int, errorCode: Int) {
            self.subsystemCode = subsystemCode
            self.errorCode = errorCode
        }
    }

    enum Feature {
        case app
        case tangemSdk
        case blockchainSdk
        case express
        case visa
        case staking
        case nft
        case walletConnect

        var errorCodeBase: Int {
            switch self {
            case .app: return 100_00_000
            case .tangemSdk: return 101_00_000
            case .blockchainSdk: return 102_00_000
            case .express: return 103_00_000
            case .visa: return 104_00_000
            case .staking: return 105_00_000
            case .nft: return 106_00_000
            case .walletConnect: return 107_00_000
            }
        }
    }
}
