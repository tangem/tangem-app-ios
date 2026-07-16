//
//  KeysManagerStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
@testable import Tangem

struct KeysManagerStub: KeysManager {
    let appsFlyer: AppsFlyerConfig = .stub
    let customerIO: CustomerIOKeys = .stub
    let surveySparrow: SurveySparrowKeys = .stub
    let moonPayKeys: MoonPayKeys = .stub
    let mercuryoWidgetId: String = ""
    let mercuryoSecret: String = ""
    let blockchainSdkKeysConfig: BlockchainSdkKeysConfig = .stub
    let tangemComAuthorization: String? = nil
    let infuraProjectId: String = ""
    let utorgSID: String = ""
    let walletConnectProjectId: String = ""
    let expressKeys: ExpressKeys = .stub
    let devExpressKeys: ExpressKeys? = nil
    let stakeKitKey: String = ""
    let moralisAPIKey: String = ""
    let blockaidAPIKey: String = ""
    let tangemApiKey: String = ""
    let tangemApiKeyDev: String = ""
    let tangemApiKeyStage: String = ""
    let amplitudeApiKey: String = ""
    let appsFlyerConfig: AppsFlyerConfig = .stub
    let yieldModuleApiKey: String = ""
    let yieldModuleApiKeyDev: String = ""
    let p2pApiKeys: P2PAPIKeys = .stub
    let bffStaticToken: String = ""
    let bffStaticTokenDev: String = ""
    let gaslessTxApiKey: String = ""
    let gaslessTxApiKeyDev: String = ""
}

// MARK: - KeysManager Type Stubs

extension AppsFlyerConfig {
    static let stub: AppsFlyerConfig = decode("""
    {"appsFlyerDevKey": "", "appsFlyerAppID": ""}
    """)
}

extension CustomerIOKeys {
    static let stub: CustomerIOKeys = decode("""
    {"iosApiKey": ""}
    """)
}

extension SurveySparrowKeys {
    static let stub: SurveySparrowKeys = decode("""
    {
        "domain": "test.surveysparrow.com",
        "apiKey": "test_token",
        "swapRating": {"surveyId": "1", "ratingQuestionId": "2", "feedbackQuestionId": "3"}
    }
    """)
}

extension MoonPayKeys {
    static let stub = MoonPayKeys(apiKey: "", secretApiKey: "")
}

extension ExpressKeys {
    static let stub: ExpressKeys = decode("""
    {"apiKey": "", "signVerifierPublicKey": ""}
    """)
}

extension P2PAPIKeys {
    static let stub: P2PAPIKeys = decode("""
    {"mainnet": "", "hoodi": ""}
    """)
}

extension BlockchainSdkKeysConfig {
    static let stub = BlockchainSdkKeysConfig(
        blockchairApiKeys: [],
        blockcypherTokens: [],
        alchemyApiKey: "",
        infuraProjectId: "",
        nowNodesApiKey: "",
        getBlockCredentials: .init(credentials: []),
        kaspaSecondaryApiUrl: nil,
        tronGridApiKey: "",
        hederaArkhiaApiKey: "",
        etherscanApiKey: "",
        koinosProApiKey: "",
        tonCenterApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
        fireAcademyApiKeys: .init(mainnetApiKey: "", testnetApiKey: ""),
        chiaTangemApiKeys: .init(mainnetApiKey: ""),
        quickNodeSolanaCredentials: .init(apiKey: "", subdomain: ""),
        quickNodeBscCredentials: .init(apiKey: "", subdomain: ""),
        quickNodeXrpCredentials: .init(apiKey: "", subdomain: ""),
        quickNodePlasmaCredentials: .init(apiKey: "", subdomain: ""),
        quickNodeMonadCredentials: .init(apiKey: "", subdomain: ""),
        bittensorDwellirKey: "",
        dwellirApiKey: "",
        bittensorOnfinalityKey: "",
        tangemAlephiumApiKey: "",
        blinkApiKey: "",
        tatumApiKey: "",
        yieldModuleApiKey: "",
        gaslessTxApiKey: ""
    )
}

private func decode<T: Decodable>(_ json: String) -> T {
    try! JSONDecoder().decode(T.self, from: json.data(using: .utf8)!)
}
