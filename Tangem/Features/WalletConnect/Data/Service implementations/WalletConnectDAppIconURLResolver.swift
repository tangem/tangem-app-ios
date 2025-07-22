//
//  WalletConnectDAppIconURLResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct UniformTypeIdentifiers.UTType
import class UIKit.UIImage
import Kingfisher
import TangemNetworkUtils

final class WalletConnectDAppIconURLResolver {
    private let remoteURLResourceResolver: RemoteURLResourceResolver
    private let kingfisherCache: ImageCache
    private let iconsToProcessLimit: UInt

    init(remoteURLResourceResolver: RemoteURLResourceResolver, kingfisherCache: ImageCache, iconsToProcessLimit: UInt = 5) {
        self.remoteURLResourceResolver = remoteURLResourceResolver
        self.kingfisherCache = kingfisherCache
        self.iconsToProcessLimit = iconsToProcessLimit
    }

    func resolveURL(from rawURLStrings: [String]) async -> URL? {
        let urlsToProcess = rawURLStrings
            .compactMap(URL.init)
            .prefix(Int(iconsToProcessLimit))

        for url in urlsToProcess {
            if kingfisherCache.isCached(forKey: url.absoluteString) {
                return url
            }
        }

        let resolvedResource: ResolvedResource? = await withTaskGroup(of: ResolvedResource?.self) { [weak self] taskGroup in
            for url in urlsToProcess {
                taskGroup.addTask {
                    await self?.process(resourceURL: url)
                }
            }

            for await resolvedResource in taskGroup {
                guard let resolvedResource else { continue }
                taskGroup.cancelAll()
                return resolvedResource
            }

            return nil
        }

        guard let resolvedResource else {
            return nil
        }

        guard resolvedResource.universalType.isSubtype(of: .image) else {
            return nil
        }

        if let resourceData = resolvedResource.data, let uiImage = UIImage(data: resourceData) {
            try? await kingfisherCache.store(uiImage, original: resourceData, forKey: resolvedResource.url.absoluteString)
        }

        return resolvedResource.url
    }

    private func process(resourceURL: URL) async -> ResolvedResource? {
        do {
            let resolvedResource = try await remoteURLResourceResolver.resolve(url: resourceURL)

            // [REDACTED_USERNAME], SVG format is not supported at the moment
            guard resolvedResource.universalType != .svg else {
                return nil
            }

            return resolvedResource
        } catch {
            return nil
        }
    }
}
