//
//  WalletConnectConnectedDAppMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectConnectedDAppMapper {
    static func mapToDomain(_ connectedDAppDTO: WalletConnectConnectedDAppPersistentDTO) -> WalletConnectConnectedDApp {
        let session = WalletConnectDAppSession(topic: connectedDAppDTO.sessionTopic, expiryDate: connectedDAppDTO.expiryDate)
        let dAppData = WalletConnectDAppData(
            name: connectedDAppDTO.dAppName,
            domain: connectedDAppDTO.dAppDomainURL,
            icon: connectedDAppDTO.dAppIconURL
        )

        return WalletConnectConnectedDApp(
            session: session,
            userWalletID: connectedDAppDTO.userWalletID,
            dAppData: dAppData,
            verificationStatus: Self.mapVerificationStatus(toDomain: connectedDAppDTO.verificationStatus),
            blockchains: connectedDAppDTO.blockchains,
            connectionDate: connectedDAppDTO.connectionDate
        )
    }

    static func mapFromDomain(_ connectedDApp: WalletConnectConnectedDApp) -> WalletConnectConnectedDAppPersistentDTO {
        WalletConnectConnectedDAppPersistentDTO(
            sessionTopic: connectedDApp.session.topic,
            userWalletID: connectedDApp.userWalletID,
            dAppName: connectedDApp.dAppData.name,
            dAppDomainURL: connectedDApp.dAppData.domain,
            dAppIconURL: connectedDApp.dAppData.icon,
            verificationStatus: mapVerificationStatus(fromDomain: connectedDApp.verificationStatus),
            blockchains: connectedDApp.blockchains,
            expiryDate: connectedDApp.session.expiryDate,
            connectionDate: connectedDApp.connectionDate
        )
    }

    // MARK: - Private

    private static func mapVerificationStatus(
        toDomain verificationStatusDTO: WalletConnectConnectedDAppPersistentDTO.VerificationStatus
    ) -> WalletConnectDAppVerificationStatus {
        switch verificationStatusDTO {
        case .verified:
            return .verified
        case .unknownDomain:
            return .unknownDomain
        case .malicious:
            return .malicious
        }
    }

    private static func mapVerificationStatus(
        fromDomain verificationStatus: WalletConnectDAppVerificationStatus
    ) -> WalletConnectConnectedDAppPersistentDTO.VerificationStatus {
        switch verificationStatus {
        case .verified:
            return .verified
        case .unknownDomain:
            return .unknownDomain
        case .malicious:
            return .malicious
        }
    }
}
