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
            let attackTypes = responseDTO.attackTypes.keys.map(Self.mapAttackType)
            return .malicious(attackTypes)

        case .miss:
            return .unknownDomain
        }
    }

    private static func mapAttackType(_ dtoAttackType: BlockaidDTO.SiteScan.Response.AttackType) -> WalletConnectDAppVerificationStatus.AttackType {
        switch dtoAttackType {
        case .signatureFarming: .signatureFarming
        case .approvalFarming: .approvalFarming
        case .setApprovalForAll: .setApprovalForAll
        case .transferFarming: .transferFarming
        case .rawEtherTransfer: .rawEtherTransfer
        case .seaportFarming: .seaportFarming
        case .blurFarming: .blurFarming
        case .permitFarming: .permitFarming
        case .other: .other
        }
    }
}
