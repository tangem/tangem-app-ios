//
//  ReceiveAddressService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol ReceiveAddressService: AnyObject {
    var addressTypes: [ReceiveAddressType] { get }
    var addressInfos: [ReceiveAddressInfo] { get }

    func update(with addresses: [Address]) async
}

// MARK: - CommonReceiveAddressService

class CommonReceiveAddressService {
    // MARK: - Private Properties

    private var _addressTypes: [ReceiveAddressType] = []

    private var resolveDestinationTask: Task<Void, Error>?

    private let domainAddressResolver: DomainNameAddressResolver?
    private let receiveAddressInfoUtils = ReceiveAddressInfoUtils(colorScheme: .whiteBlack)

    // MARK: - Init

    init(addresses: [Address], domainAddressResolver: DomainNameAddressResolver?) {
        self.domainAddressResolver = domainAddressResolver

        updateReceiveAddressTypes(with: addresses)
    }
}

// MARK: - ReceiveAddressService

extension CommonReceiveAddressService: ReceiveAddressService {
    var addressTypes: [ReceiveAddressType] {
        _addressTypes
    }

    var addressInfos: [ReceiveAddressInfo] {
        _addressTypes.map { $0.info }
    }

    func update(with addresses: [Address]) async {
        updateReceiveAddressTypes(with: addresses)

        resolveDestinationTask?.cancel()

        resolveDestinationTask = runTask(in: self) { service in
            await service.resolveDomainAddressTypes()
        }

        _ = try? await resolveDestinationTask?.value
    }

    // MARK: - Private Implementation

    private func resolveDomainAddressTypes() async {
        guard let domainAddressResolver else {
            return
        }

        for addressInfo in addressInfos {
            do {
                let resolveDomainName = try await domainAddressResolver.resolveDomainName(addressInfo.address)
                _addressTypes.append(.domain(resolveDomainName, addressInfo))
            } catch is CancellationError {
                // Do Nothig
            } catch {
                AppLogger.error("Failed to check resolve address with error:", error: error)
            }
        }
    }

    private func updateReceiveAddressTypes(with addresses: [Address]) {
        let addressInfos = receiveAddressInfoUtils.makeAddressInfos(from: addresses)
        _addressTypes = addressInfos.map { ReceiveAddressType.address($0) }
    }
}

// MARK: - Dummy

class DummyReceiveAddressService: ReceiveAddressService {
    private let receiveAddressInfoUtils = ReceiveAddressInfoUtils(colorScheme: .whiteBlack)

    var addressTypes: [ReceiveAddressType] {
        _addressInfos.map { .address($0) }
    }

    var addressInfos: [ReceiveAddressInfo] {
        _addressInfos
    }

    func update(with addresses: [Address]) async {
        _addressInfos = receiveAddressInfoUtils.makeAddressInfos(from: addresses)
    }

    // MARK: - Private Properties

    private var _addressInfos: [ReceiveAddressInfo]

    // MARK: - Init

    init(addressInfos: [ReceiveAddressInfo]) {
        _addressInfos = addressInfos
    }
}
