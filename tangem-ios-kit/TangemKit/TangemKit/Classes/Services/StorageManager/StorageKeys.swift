//
//  StorageKeys.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum StorageKey: String {
    case cids //запоминаем все сканированные карты
    case terminalPrivateKey //link card to terminal
    case terminalPublicKey
}
