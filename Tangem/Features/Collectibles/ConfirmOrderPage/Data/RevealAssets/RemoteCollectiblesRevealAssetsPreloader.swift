//
//  RemoteCollectiblesRevealAssetsPreloader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Kingfisher
import SwiftUI
import TangemCollectibles
import TangemFoundation

@MainActor
final class RemoteCollectiblesRevealAssetsPreloader: CollectiblesRevealAssetsPreloader {
    // MARK: - Properties

    private let openingMedia: CollectiblesMachine.OpeningMedia
    private let openingMediaProvider: any CollectiblesOpeningMediaProvider

    private var openingMediaTask: Task<Void, Never>?
    private var queuedColorScheme: ColorScheme?
    private var localMediaURLs: [URL: URL] = [:]

    // MARK: - Init

    init(
        openingMedia: CollectiblesMachine.OpeningMedia,
        openingMediaProvider: any CollectiblesOpeningMediaProvider = RemoteCollectiblesOpeningMediaProvider()
    ) {
        self.openingMedia = openingMedia
        self.openingMediaProvider = openingMediaProvider
    }

    func preload(for colorScheme: ColorScheme) {
        guard openingMediaTask == nil else {
            queuedColorScheme = colorScheme
            return
        }

        let videoURL = colorScheme == .dark ? openingMedia.darkVideoURL : openingMedia.lightVideoURL
        let remoteURLs = [videoURL, openingMedia.skipAudioURL].compactMap { $0 }.filter { localMediaURLs[$0] == nil }

        guard !remoteURLs.isEmpty else { return }

        openingMediaTask = Task { [weak self, openingMediaProvider] in
            await withTaskGroup(of: (URL, URL?).self) { group in
                for remoteURL in remoteURLs {
                    group.addTask { (remoteURL, await Self.load(remoteURL, with: openingMediaProvider)) }
                }

                for await (remoteURL, localURL) in group {
                    if let localURL {
                        self?.localMediaURLs[remoteURL] = localURL
                    }
                }
            }

            self?.finishOpeningMediaLoading()
        }
    }

    func assets(prefetchingImages imageURLs: [URL]) async -> CollectiblesRevealAssets {
        let start = ContinuousClock.now
        let imagesPrefetch = Task { await ImagePrefetcher.prefetch(imageURLs) }

        await waitAtMost(Constants.wonCardImagesWaitTimeout) { await imagesPrefetch.value }
        await waitAtMost(Constants.openingMediaWaitTimeout - (ContinuousClock.now - start)) { [weak self] in
            while let task = await self?.openingMediaTask {
                await task.value
            }
        }

        return CollectiblesRevealAssets(
            darkVideoURL: localMediaURL(for: openingMedia.darkVideoURL),
            lightVideoURL: localMediaURL(for: openingMedia.lightVideoURL),
            skipAudioURL: localMediaURL(for: openingMedia.skipAudioURL)
        )
    }
}

// MARK: - Private logic

private extension RemoteCollectiblesRevealAssetsPreloader {
    func finishOpeningMediaLoading() {
        openingMediaTask = nil

        guard let queuedColorScheme else { return }

        self.queuedColorScheme = nil
        preload(for: queuedColorScheme)
    }

    func waitAtMost(_ timeout: Duration, for work: @escaping @Sendable () async -> Void) async {
        do {
            try await Task.run(withTimeout: timeout, code: work)
        } catch {
            return
        }
    }

    func localMediaURL(for remoteURL: URL?) -> URL? {
        remoteURL.flatMap { localMediaURLs[$0] }
    }

    nonisolated static func load(_ remoteURL: URL, with provider: any CollectiblesOpeningMediaProvider) async -> URL? {
        do {
            return try await provider.load(from: remoteURL)
        } catch is CancellationError {
            return nil
        } catch {
            CollectiblesLogger.error("Collectibles opening media \(remoteURL.lastPathComponent) failed", error: error)
            return nil
        }
    }
}

// MARK: - Image prefetching

private extension ImagePrefetcher {
    static func prefetch(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }

        await withCheckedContinuation { continuation in
            ImagePrefetcher(urls: urls, completionHandler: { _, _, _ in continuation.resume() }).start()
        }
    }
}

// MARK: - Constants

private extension RemoteCollectiblesRevealAssetsPreloader {
    enum Constants {
        static let openingMediaWaitTimeout: Duration = .seconds(5)
        static let wonCardImagesWaitTimeout: Duration = .seconds(3)
    }
}
