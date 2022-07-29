//
//  ZendeskConfig.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 22.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ZendeskConfig: Decodable {
    let zendeskApiKey: String
    let zendeskAppId: String
    let zendeskClientId: String
    let zendeskUrl: String
    let zendeskAccountKey: String
}
