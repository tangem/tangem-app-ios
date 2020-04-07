//
//  RobotApi.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum PhonePosition: String {
    case phone1
}

public enum CardPosition: String {
    case red
    case black
    case none
}

public class RobotApi {
    public func select(card: CardPosition, for phone: PhonePosition = .phone1) {
        let endpoint = "http://192.168.10.40/arduino/test/\(phone.rawValue)/\(card.rawValue)/0"
        let url = URL(string: endpoint)!
        URLSession.shared.dataTask(with: url).resume()
    }
}
