// qMD - Resource lookup helper
// Resolves bundled resources without going through SwiftPM's `Bundle.module`
// accessor. The SPM-generated accessor for executable targets only checks
// `Bundle.main.bundleURL/qmd_qmd.bundle` (which never matches the .app
// layout, where the bundle lives in Contents/Resources) and a hardcoded
// absolute path into the build machine's .build directory, then calls
// `fatalError` on miss. That trap crashed packaged installs at launch
// (v1.7.2 and earlier). This helper probes a set of candidate directories
// with plain filesystem checks and returns nil on miss instead of trapping.

import Foundation

// Anchor for Bundle(for:). In the packaged app this resolves to the .app
// bundle; under `swift test` it resolves to the .xctest bundle that links
// the qmd module, whose parent directory holds qmd_qmd.bundle.
private final class ResourceBundleFinder {}

enum ResourceLoader {
    // SwiftPM resource bundle name for the qmd target.
    private static let resourceBundleName = "qmd_qmd.bundle"

    // Directories that may contain qmd_qmd.bundle or a bare resource file.
    private static var searchRoots: [URL] {
        var roots: [URL] = []
        if let url = Bundle.main.resourceURL {
            roots.append(url)
        }
        let hostBundle = Bundle(for: ResourceBundleFinder.self)
        if let url = hostBundle.resourceURL {
            roots.append(url)
        }
        // Siblings of the hosting bundles: under `swift test` the resource
        // bundle sits next to the .xctest bundle in the build directory.
        roots.append(hostBundle.bundleURL.deletingLastPathComponent())
        roots.append(Bundle.main.bundleURL.deletingLastPathComponent())
        return roots
    }

    static func url(forResource name: String, ext: String, subdirectory: String? = nil) -> URL? {
        if let direct = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return direct
        }

        let fileManager = FileManager.default
        let filename = "\(name).\(ext)"

        for root in searchRoots {
            var candidate = root.appendingPathComponent(resourceBundleName)
            if let sub = subdirectory, !sub.isEmpty {
                candidate.appendPathComponent(sub)
            }
            candidate.appendPathComponent(filename)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }

            let flat = root.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: flat.path) {
                return flat
            }
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
