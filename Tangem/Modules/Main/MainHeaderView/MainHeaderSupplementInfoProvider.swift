//
//  MainHeaderInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainHeaderSupplementInfoProvider: AnyObject {
    var userWalletNamePublisher: AnyPublisher<String, Never> { get }
}
