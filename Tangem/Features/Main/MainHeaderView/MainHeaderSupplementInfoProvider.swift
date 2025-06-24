//
//  MainHeaderInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets

protocol MainHeaderSupplementInfoProvider: AnyObject {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { get }
    var userWalletNamePublisher: AnyPublisher<String, Never> { get }
}
