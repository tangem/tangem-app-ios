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

    func update() async
    func clear()
}

// MARK: - CommonReceiveAddressService

class CommonReceiveAddressService {
    // MARK: - Private Properties

    private let _addressInfos: [ReceiveAddressInfo]
    private var _addressTypes: [ReceiveAddressType] = []

    private let domainAddressResolver: DomainNameAddressResolver?

    private var resolveDestinationTask: Task<Void, Error>?

    // MARK: - Init

    init(addresses: [Address], domainAddressResolver: DomainNameAddressResolver?) {
        _addressInfos = ReceiveAddressInfoUtils().makeAddressInfos(from: addresses)
        self.domainAddressResolver = domainAddressResolver
    }
}

// MARK: - ReceiveAddressService

extension CommonReceiveAddressService: ReceiveAddressService {
    var addressTypes: [ReceiveAddressType] {
        _addressTypes
    }

    var addressInfos: [ReceiveAddressInfo] {
        _addressInfos
    }

    func update() async {
        resolveDestinationTask?.cancel()

        resolveDestinationTask = runTask(in: self) { service in
            await service.resolveReceiveAssetsWithoutDomainResolver()

            if let domainAddressResolver = service.domainAddressResolver {
                await service.resolveReceiveAssets(with: domainAddressResolver)
            }
        }

        _ = try? await resolveDestinationTask?.value
    }

    func clear() {
        _addressTypes = []
    }

    // MARK: - Private Implementation

    private func resolveReceiveAssets(with domainNameAddressResolver: DomainNameAddressResolver) async {
        for addressInfo in _addressInfos {
            do {
                let resolveDomainName = try await domainNameAddressResolver.resolveDomainName(addressInfo.address)
                _addressTypes.append(.domain(resolveDomainName, addressInfo))
            } catch is CancellationError {
                // Do Nothig
            } catch {
                AppLogger.error("Failed to check resolve address with error:", error: error)
            }
        }
    }

    private func resolveReceiveAssetsWithoutDomainResolver() async {
        _addressTypes = _addressInfos.map { ReceiveAddressType.address($0) }
    }
}

// MARK: - Dummy

class DummyReceiveAddressService: ReceiveAddressService {
    var addressTypes: [ReceiveAddressType] {
        _addressInfos.map { .address($0) }
    }

    var addressInfos: [ReceiveAddressInfo] {
        _addressInfos
    }

    func update() async {}

    func clear() {}

    // MARK: - Private Properties

    private let _addressInfos: [ReceiveAddressInfo]

    // MARK: - Init

    init(addressInfos: [ReceiveAddressInfo]) {
        _addressInfos = addressInfos
    }
}
