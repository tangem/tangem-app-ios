//
//  WalletConnectConnectedDAppMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectConnectedDAppMapper {
    static func mapToDomain(_ connectedDAppDTO: WalletConnectConnectedDAppPersistentDTO) -> WalletConnectConnectedDApp {
        let session = WalletConnectDAppSession(
            topic: connectedDAppDTO.sessionTopic,
            namespaces: mapNamespaces(toDomain: connectedDAppDTO.namespaces),
            expiryDate: connectedDAppDTO.expiryDate
        )

        let dAppData = WalletConnectDAppData(
            name: connectedDAppDTO.dAppName,
            domain: connectedDAppDTO.dAppDomainURL,
            icon: connectedDAppDTO.dAppIconURL
        )

        return WalletConnectConnectedDApp(
            session: session,
            userWalletID: connectedDAppDTO.userWalletID,
            dAppData: dAppData,
            verificationStatus: mapVerificationStatus(toDomain: connectedDAppDTO.verificationStatus),
            dAppBlockchains: connectedDAppDTO.dAppBlockchains.map(mapDAppBlockchain(toDomain:)),
            connectionDate: connectedDAppDTO.connectionDate
        )
    }

    static func mapFromDomain(_ connectedDApp: WalletConnectConnectedDApp) -> WalletConnectConnectedDAppPersistentDTO {
        WalletConnectConnectedDAppPersistentDTO(
            sessionTopic: connectedDApp.session.topic,
            namespaces: mapNamespaces(fromDomain: connectedDApp.session.namespaces),
            userWalletID: connectedDApp.userWalletID,
            dAppName: connectedDApp.dAppData.name,
            dAppDomainURL: connectedDApp.dAppData.domain,
            dAppIconURL: connectedDApp.dAppData.icon,
            verificationStatus: mapVerificationStatus(fromDomain: connectedDApp.verificationStatus),
            dAppBlockchains: connectedDApp.dAppBlockchains.map(mapDAppBlockchain(fromDomain:)),
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

    private static func mapDAppBlockchain(
        toDomain dAppBlockchainDTO: WalletConnectConnectedDAppPersistentDTO.DAppBlockchain
    ) -> WalletConnectDAppBlockchain {
        WalletConnectDAppBlockchain(blockchain: dAppBlockchainDTO.blockchain, isRequired: dAppBlockchainDTO.isRequired)
    }

    private static func mapDAppBlockchain(
        fromDomain dAppBlockchain: WalletConnectDAppBlockchain
    ) -> WalletConnectConnectedDAppPersistentDTO.DAppBlockchain {
        WalletConnectConnectedDAppPersistentDTO.DAppBlockchain(blockchain: dAppBlockchain.blockchain, isRequired: dAppBlockchain.isRequired)
    }

    private static func mapNamespaces(
        toDomain namespacesDTOs: [String: WalletConnectConnectedDAppPersistentDTO.SessionNamespace]
    ) -> [String: WalletConnectSessionNamespace] {
        namespacesDTOs.mapValues(mapSessionNamespace(toDomain:))
    }

    private static func mapNamespaces(
        fromDomain domainNamespaces: [String: WalletConnectSessionNamespace]
    ) -> [String: WalletConnectConnectedDAppPersistentDTO.SessionNamespace] {
        domainNamespaces.mapValues(mapSessionNamespace(fromDomain:))
    }

    private static func mapSessionNamespace(
        toDomain namespaceDTO: WalletConnectConnectedDAppPersistentDTO.SessionNamespace
    ) -> WalletConnectSessionNamespace {
        WalletConnectSessionNamespace(
            blockchains: namespaceDTO.blockchains,
            accounts: namespaceDTO.accounts.map(mapAccount(toDomain:)),
            methods: namespaceDTO.methods,
            events: namespaceDTO.events
        )
    }

    private static func mapSessionNamespace(
        fromDomain domainNamespace: WalletConnectSessionNamespace
    ) -> WalletConnectConnectedDAppPersistentDTO.SessionNamespace {
        WalletConnectConnectedDAppPersistentDTO.SessionNamespace(
            blockchains: domainNamespace.blockchains,
            accounts: domainNamespace.accounts.map(mapAccount(fromDomain:)),
            methods: domainNamespace.methods,
            events: domainNamespace.events
        )
    }

    private static func mapAccount(toDomain accountDTO: WalletConnectConnectedDAppPersistentDTO.Account) -> WalletConnectAccount {
        WalletConnectAccount(namespace: accountDTO.namespace, reference: accountDTO.reference, address: accountDTO.address)
    }

    private static func mapAccount(fromDomain domainAccount: WalletConnectAccount) -> WalletConnectConnectedDAppPersistentDTO.Account {
        WalletConnectConnectedDAppPersistentDTO.Account(
            namespace: domainAccount.namespace,
            reference: domainAccount.reference,
            address: domainAccount.address
        )
    }
}
