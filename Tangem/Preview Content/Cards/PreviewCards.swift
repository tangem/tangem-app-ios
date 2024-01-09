//
//  PreviewCards.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

extension Card {
    static var walletWithBackup: Card {
        return decodeFromURL(walletWithBackupURL)!
    }

    static var walletV2: Card {
        return decodeFromURL(walletV2URL)!
    }

    static var twin: Card {
        return decodeFromURL(twinURL)!
    }

    static var xrpNote: Card {
        return decodeFromURL(xrpNoteURL)!
    }

    static var xlmBird: Card {
        return decodeFromURL(xlmBirdURL)!
    }

    static var visa: Card {
        return decodeFromURL(visaURL)!
    }

    private static var walletWithBackupURL: URL {
        url(fileName: "walletWithBackup")
    }

    private static var walletV2URL: URL {
        url(fileName: "walletV2")
    }

    private static var twinURL: URL {
        url(fileName: "twinCard")
    }

    private static var xrpNoteURL: URL {
        url(fileName: "xrpNote")
    }

    private static var xlmBirdURL: URL {
        url(fileName: "xlmBird")
    }

    private static var visaURL: URL {
        url(fileName: "visa")
    }

    private static func url(fileName: String) -> URL {
        Bundle.main.url(forResource: fileName, withExtension: "json")!
    }

    private static func decodeFromURL(_ url: URL) -> Card? {
        print("Attempt to decode file at url: \(url)")
        let dataStr = try! String(contentsOf: url)
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            print(dataStr)
            return try decoder.decode(Card.self, from: dataStr.data(using: .utf8)!)
        } catch {
            print("Failed to decode card. Reason: \(error)")
        }
        return nil
    }
}
