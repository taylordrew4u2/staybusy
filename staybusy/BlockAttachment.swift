//
//  BlockAttachment.swift
//  staybusy
//
//  CloudKit-synced binary payload for a block's attachments — boarding
//  passes, photos, PDFs. Sits alongside the legacy
//  `Block.attachmentFilenames` strings: those track ordering and act
//  as cache keys for the local Documents directory; this model carries
//  the actual bytes so files appear on every signed-in device.
//
//  `@Attribute(.externalStorage)` keeps the blob out of the SQLite row
//  (stored as a sidecar file) which keeps queries fast and lets
//  CloudKit ship it as a CKAsset under the hood.
//

import Foundation
import SwiftData

@Model
final class BlockAttachment {
    @Attribute(.externalStorage)
    var data: Data = Data()

    /// Mirrors a filename in the local Documents directory. We use it
    /// as the join key — once `materialize()` writes the bytes to that
    /// path, the existing URL-based display code finds the file by
    /// looking up this name in `block.attachmentFilenames`.
    var filename: String = ""

    var createdAt: Date = Date()

    /// Parent block. Optional because the CloudKit-backed SwiftData
    /// configuration requires every relationship to be nullable.
    var block: Block?

    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
        self.createdAt = Date()
    }
}
