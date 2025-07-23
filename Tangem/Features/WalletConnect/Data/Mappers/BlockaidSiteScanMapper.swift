//
//  BlockaidSiteScanMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum BlockaidSiteScanMapper {
    static func mapToDomain(_ responseDTO: BlockaidDTO.SiteScan.Response) -> WalletConnectDAppVerificationStatus {
        switch responseDTO.status {
        case .hit where !responseDTO.isMalicious:
            return .verified

        case .hit:
            return .malicious

        case .miss:
            return .unknownDomain
        }
    }
}
