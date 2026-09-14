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
    func localURL(remoteURL url: URL, checksum: String) async -> URL? {
        if url.isFileURL { return url }

        let destination = dir.appendingPathComponent(fileName(checksum: checksum, url: url))

        if FileManager.default.fileExists(atPath: destination.path) {
            touch(destination)
            return destination
        }

        do {
            let tempURL = try await dataLoader.downloadFile(from: url)
            try? FileManager.default.removeItem(at: destination)
            // Atomic rename: a partially written temp file is never seen as a cache hit.
            try FileManager.default.moveItem(at: tempURL, to: destination)
            touch(destination)
            enforceSizeLimit(keeping: destination)
            return destination
        } catch {
            return nil
        }
    }

    // MARK: - Private

    /// Hashed rather than used verbatim: neither value is a safe file name on its own.
    private func fileName(checksum: String, url: URL) -> String {
        let name = (checksum.isEmpty ? url.absoluteString : checksum).sha256()

        guard !url.pathExtension.isEmpty else { return name }

        return "\(name).\(url.pathExtension)"
    }

    private func touch(_ url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    /// The just-written file is exempt from eviction — its URL is already promised to the caller,
    /// so a single oversized asset may briefly overshoot the limit until the next write.
    private func enforceSizeLimit(keeping freshURL: URL) {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys) else {
            return
        }

        var entries = files.compactMap { url -> (url: URL, size: Int, date: Date)? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), let size = values.fileSize else { return nil }
            return (url, size, values.contentModificationDate ?? .distantPast)
        }

        var total = entries.reduce(0) { $0 + $1.size }
        guard total > maxBytes else { return }

        entries.sort { $0.date < $1.date }
        for entry in entries where total > maxBytes && entry.url != freshURL {
            try? FileManager.default.removeItem(at: entry.url)
            total -= entry.size
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
