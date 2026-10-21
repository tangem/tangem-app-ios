//
//  SolanaNFTFixtures.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum SolanaNFTFixtures {
    enum Programmable {
        static let mint = "7Kny3iBH1MSjeeFQMpGc2sWsFscyuoosSBHMS67ZoPX4"
        static let owner = "A9Jn6HqVd5oPdT3YTJjnDMh3vZDVpz8j1HnxygsNxdBo"
        static let ownerToken = "6FW2VaYZVyPk2bSg32WwCeigKTrYN7knWBSkyQ37NLXu"
        static let destinationOwner = "5Y5zMeo3EtRBt6QFQMmJCyG1xcHfiUDH1buhVryLHarv"
        static let destinationToken = "4ZNPdLsBtxTJQ5BXsFSPYRgsKaYAaaYJRyuK33yXVYp9"
        static let metadata = "4SCNiHv67kq9LhoXwvGZramY9SVfobvbHgn7x4gF55pg"
        static let edition = "CEZ54V8s54nG4di5JpSX6AVJ7egkx2NouUBAPCVDAubD"
        static let ownerTokenRecord = "CvDkKDiDD6TNEQopLtcPKaJcsn5f8X5KCwG7giMG1fyC"
        static let destinationTokenRecord = "7LKkyrDutQW5uD1o8ttA67GvRXdymGccrU7xF3rNnF9M"
        static let ruleSet = "7j2KxTBnZjNuxXEj6m8D7J4jrnNJZCbrVPiBwCyHTasJ"
        static let transferData = "3100010000000000000000"

        static let metadataAccountData = Data(base64Encoded: [
            "BH77qzv3ukVp4w6aJ96Mgce9PvztdN1l4+LflSigeGW/XfaM55AZFViiGlCXseIwMiQ5Bt1T9V3MB768Y3M9SJcgAAAAUmVnaW9u",
            "IDc5ICMyODE2AAAAAAAAAAAAAAAAAAAAAAAKAAAAUkVHSU9OAAAAAMgAAABodHRwczovL2JhZnliZWljeWpxeGU0dmQ3eDYzeWQ3",
            "a3BnNG1saGtvdXQzN2htYW50N243eXlncHJ0ZzIzMndnNnNpLmlwZnMubmZ0c3RvcmFnZS5saW5rLzI4MTYuanNvbgAAAAAAAAAA",
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            "AAAAAAAAAAAAAAAAAAAAAAAAALwCAQUAAABZXAeAI7443IPeej/GveXikl1Vuyy26zPD0j1e0DOzHAEAQuHhgi8DuCecYvMQZTpd",
            "uLVqfiK6BsADaFnYEcoj6ggAVZiZTJbsGtilESlaiM7zaFrBnkDReBTzOR1wHru51Jl2AAWN1wGEjE11z4og+rlFP5Ciz14FbxTl",
            "3URMRR+2Un/fLwAFBkGcBkUw9tZCZ0LZO/zNm0eC2ydanwqeaU/Slb/O++0ABQEBAf8BBAAAAAEAAWPqBArCVN4aRmyL44LQN1kb",
            "3ktQly8QTVeSUE9d3KjZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            "AAAAAAAAAA==",
        ].joined())!

        static let unlockedTokenRecordData = Data(base64Encoded: [
            "C/8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            "AAAAAAA=",
        ].joined())!
    }

    enum Core {
        static let asset = "3xYi4gjZ8HKp8N2yEHiYKjVrTKX3K9KcC33qYxWzbDFZ"
        static let owner = "CUfZZHt9nNsSnQUv5jhGGLbRRtudpWvzoSwbJQf7T9PW"
        static let collection = "CCryptUfeFSZ3Fgc9FLeKrhLVAP67FSqi1GuVoj9CRac"
        static let assetFreezeFlagOffset = 180
        static let collectionFreezeFlagOffset = 140

        static func assetAccountData(withExternalPluginCheckingEvent lifecycleEvent: UInt8) -> Data {
            var data = Data([1]) + PublicKey(string: owner)!.data + Data([0])
            data += Data([0, 0, 0, 0]) + Data([0, 0, 0, 0]) + Data([0])
            let registryOffset = UInt64(data.count + 9)
            data += Data([3]) + withUnsafeBytes(of: registryOffset.littleEndian) { Data($0) }
            data += Data([4]) + Data([0, 0, 0, 0]) + Data([1, 0, 0, 0])
            data += Data([1, 2]) + Data([1]) + Data([1, 0, 0, 0]) + Data([lifecycleEvent]) + Data([4, 0, 0, 0])
            data += Data(repeating: 0, count: 8) + Data([0, 0])
            return data
        }

        static let assetAccountData = Data(base64Encoded: [
            "AaqG1ub7Gwt3NtdoDiVAXjJ0HulDNsf8P34LNgJ+V16pAqZ6dRaY8L8+Hhp++hRPRifaIbCLArWnKuZKz/eETB71IAAAADIwMDIg",
            "UG9rZW1vbiBOZW8gRGVzdGlueSBVbm93biBUPwAAAGh0dHBzOi8vYXJ3ZWF2ZS5uZXQvZVRKMXZhUWtvY1Y3Nk1vTkdKSFVyMXhB",
            "Rk1tSm1jT2Y5OVprOE85QUdzUQADtQAAAAAAAAAFAAQBAAAABQPJjkAsrQawTeH+/5LTROkPW7AiNa7dg+uqIX9auuKPRbMAAAAA",
            "AAAAAAAAAA==",
        ].joined())!

        static let collectionAccountData = Data(base64Encoded: [
            "BbhJvSf1pWAOic+nA+axhrqDqHE78GhDY+x+MkbVM/zyDwAAAENvbGxlY3RvciBDcnlwdD8AAABodHRwczovL2Fyd2VhdmUubmV0",
            "L0ZJNDJnanZTWGJEMzVQNkVZSlBZeWdYQm11M3BsY08yWGRVMXJDWTVsQVE0DwIAacABAAPbAAAAAAAAAA8HCAUAAMgAAQAAAGiL",
            "zo86jCq0M6Eezfd9TFIvP+4/GjN8INn0lFHveqLMZAAEAQAAAMmOQCytBrBN4f7/ktNE6Q9bsCI1rt2D66ohf1q64o9FBAYAAAAP",
            "A5iLgOt5NShpsiR0X1ndv4omWMoT3GiBISY1HK4HwaWliAAAAAAAAAAHAokAAAAAAAAACAKKAAAAAAAAAAUDyY5ALK0GsE3h/v+S",
            "00TpD1uwIjWu3YPrqiF/Wrrij0WLAAAAAAAAAAACjQAAAAAAAAAEArYAAAAAAAAAAAAAAA==",
        ].joined())!
    }
}
