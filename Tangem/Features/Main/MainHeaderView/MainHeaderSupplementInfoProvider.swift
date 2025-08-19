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
    var name: String { get }
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { get }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { get }
}
