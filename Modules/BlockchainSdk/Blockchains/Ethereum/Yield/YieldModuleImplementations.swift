//
//  YieldModuleImplementations.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum YieldModuleVersion: Int, Comparable {
    case v1 = 1
    case v2 = 2
    case v3 = 3

    public static func < (lhs: YieldModuleVersion, rhs: YieldModuleVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum YieldModuleImplementations {
    private static let addressComparator = AddressComparator()

    public static func latestVersion(for blockchain: Blockchain) -> YieldModuleVersion? {
        implementations(for: blockchain).keys.max()
    }

    public static func version(ofImplementation address: String, on blockchain: Blockchain) -> YieldModuleVersion? {
        implementations(for: blockchain).first { addressComparator.addressesMatch($0.value, address, blockchain: blockchain) }?.key
    }

    static func implementations(for blockchain: Blockchain) -> [YieldModuleVersion: String] {
        switch blockchain {
        case .ethereum(false):
            return [
                .v1: "0x06c561600016398430cC48be17292B87b1C0DB5F",
                .v2: "0xa6a6afa45D22aE7a55abC5cbBF426Fc8Dd45b846",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .bsc(false):
            return [
                .v1: "0x4fF6178B58a51Cb74E50254ED1e9ebd4F28Eb2C0",
                .v2: "0x6bBB8DDB265A6bae01422fF815a77e72D71F4e17",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .polygon(false):
            return [
                .v1: "0xC49B1438c8639AB48953e9091E5277D4C65003f0",
                .v2: "0x66084220E3dFdd1D8C8F1F868C103F9418DEce7c",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .arbitrum(false):
            return [
                .v1: "0xb48a9f0e783bD6e3359e5601A7E5825316030c82",
                .v2: "0xDC8123e7E28D8cC12c3420CF8c8D6eceD9db4c71",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .base(false):
            return [
                .v1: "0x8b645CDfE21F9553E51231dcF87c9edBdFD7d92C",
                .v2: "0x66cC410eC0Dd4013b7dA0a003404F6c503109093",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .optimism(false), .avalanche(false):
            return [
                .v1: "0x4fF6178B58a51Cb74E50254ED1e9ebd4F28Eb2C0",
                .v2: "0xe1d0BF13C427C4B2e25Df0CA29E1Faa2d10458f3",
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        case .monad(false):
            return [
                .v3: "0xaaF16358336a5e292b1D70057f99c3f2e8241C63",
            ]
        default:
            return [:]
        }
    }
}
