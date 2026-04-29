// qMD - Resource lookup helper
// Resolves bundled resources without going through SwiftPM's `Bundle.module`
// accessor. The SPM-generated accessor calls `fatalError` if its candidate
// directories don't yield a loadable NSBundle, which has been observed to
// crash the app at launch on some user machines. This helper checks the
// app's main bundle and the SPM resource subdirectory directly, returning
// nil on miss instead of trapping.

import Foundation

enum ResourceLoader {
    static func url(forResource name: String, ext: String, subdirectory: String? = nil) -> URL? {
        let main = Bundle.main

        if let direct = main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return direct
        }

        guard let resourceRoot = main.resourceURL else { return nil }

        let bundleRoot = resourceRoot.appendingPathComponent("qmd_qmd.bundle")
        var candidate = bundleRoot
        if let sub = subdirectory, !sub.isEmpty {
            candidate.appendPathComponent(sub)
        }
        candidate.appendPathComponent("\(name).\(ext)")
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        let flat = resourceRoot.appendingPathComponent("\(name).\(ext)")
        if FileManager.default.fileExists(atPath: flat.path) {
            return flat
        }

        return nil
    }

    static func string(forResource name: String, ext: String, subdirectory: String? = nil) -> String? {
        guard let url = url(forResource: name, ext: ext, subdirectory: subdirectory) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
