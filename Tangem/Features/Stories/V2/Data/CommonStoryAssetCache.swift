//
//  CommonStoryAssetCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation
import TangemStories

/// Disk cache for story assets: a remote file is downloaded once, a local one passes through.
/// Evicted LRU, capped by total size.
actor CommonStoryAssetCache: StoryAssetCaching {
    private let dir: URL
    private let maxBytes: Int
    private let dataLoader: StoriesDataLoader

    /// Two callers for one file share a download; the exists-check runs inside the shared task, so a
    /// caller arriving mid-write joins it instead of starting over.
    private let downloads = KeyedTaskProcessor<URL, URL>()

    init(
        directory: URL = Constants.defaultDirectory,
        maxBytes: Int = Constants.maxBytes,
        dataLoader: StoriesDataLoader = CommonStoriesDataLoader()
    ) {
        dir = directory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.maxBytes = maxBytes
        self.dataLoader = dataLoader
    }

    /// A new checksum means a new file, so a new story version never hits an old one. Without a
    /// checksum the URL keys the entry, and content replaced behind that URL is not picked up.
    func localURL(remoteURL url: URL, checksum: String) async throws -> URL {
        if url.isFileURL { return url }

        let destination = dir.appendingPathComponent(fileName(checksum: checksum, url: url))

        return try await downloads.execute(forKey: destination) { [self] in
            try await downloadIfMissing(url, to: destination)
        }
    }

    // MARK: - Private

    private func downloadIfMissing(_ url: URL, to destination: URL) async throws -> URL {
        if FileManager.default.fileExists(atPath: destination.path) {
            touch(destination)
            return destination
        }

        do {
            let tempURL = try await dataLoader.downloadFile(from: url)
            // Atomic rename: a partially written temp file is never seen as a cache hit.
            try FileManager.default.moveItem(at: tempURL, to: destination)
            touch(destination)
            enforceSizeLimit(keeping: destination)
            return destination
        } catch {
            AppLogger.error("Story asset download failed: \(url.lastPathComponent)", error: error)
            throw error
        }
    }

    /// Hashed rather than used verbatim: neither value is a safe file name on its own.
    private func fileName(checksum: String, url: URL) -> String {
        let name = (checksum.isEmpty ? url.absoluteString : checksum).sha256()

        guard !url.pathExtension.isEmpty else { return name }

        return "\(name).\(url.pathExtension)"
    }

    private func touch(_ url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    /// The file just written is exempt — its URL is already promised to a caller. Runs without an
    /// await, so two downloads finishing together never evict against the same listing.
    private func enforceSizeLimit(keeping freshURL: URL) {
        var entries = cacheEntries()
        var total = entries.reduce(0) { $0 + $1.size }

        guard total > maxBytes else { return }

        entries.sort { $0.date < $1.date }

        for entry in entries where entry.url.lastPathComponent != freshURL.lastPathComponent {
            guard total > maxBytes else { break }

            try? FileManager.default.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    private func cacheEntries() -> [(url: URL, size: Int, date: Date)] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys) else {
            return []
        }

        return files.compactMap { url -> (url: URL, size: Int, date: Date)? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), let size = values.fileSize else { return nil }
            return (url, size, values.contentModificationDate ?? .distantPast)
        }
    }
}

// MARK: - Constants

extension CommonStoryAssetCache {
    enum Constants {
        static let maxBytes = 200 * 1024 * 1024

        static var defaultDirectory: URL {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("StoryAssetCache", isDirectory: true)
        }
    }
}
