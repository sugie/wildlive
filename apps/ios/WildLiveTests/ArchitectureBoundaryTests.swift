// WildLive — Architecture boundary tests.
//
// Enforces the layer rules recorded in apps/ios/ARCHITECTURE.md by
// walking the source tree with FileManager and asserting that forbidden
// tokens do not appear in the layers they must not appear in. No
// third-party library involved.
//
// The rules encoded here match the ADR:
//
//   Presentation/*  MUST NOT reference URLSession or UserDefaults directly
//   Application/*   MUST NOT import SwiftUI, MUST NOT reference URLSession
//                   or UserDefaults directly
//   Domain/*        MUST NOT import SwiftUI, MUST NOT reference URLSession,
//                   UserDefaults, or Foundation-URL types beyond value ones
//   Data/*          MUST NOT import SwiftUI
//
// If these tests break, either the code drifted from the intended
// architecture, or the architecture ADR was updated and this test needs
// to catch up. Both are legitimate; the goal is that neither happens
// silently.

import XCTest
@testable import WildLive

final class ArchitectureBoundaryTests: XCTestCase {

    // MARK: - Rules

    func test_presentation_layer_does_not_use_URLSession() throws {
        try assertLayer("Presentation", forbidsSubstrings: ["URLSession"])
    }

    func test_presentation_layer_does_not_use_UserDefaults() throws {
        try assertLayer("Presentation", forbidsSubstrings: ["UserDefaults"])
    }

    func test_application_layer_does_not_import_SwiftUI() throws {
        try assertLayer("Application", forbidsSubstrings: ["import SwiftUI"])
    }

    func test_application_layer_does_not_use_URLSession() throws {
        try assertLayer("Application", forbidsSubstrings: ["URLSession"])
    }

    func test_application_layer_does_not_use_UserDefaults() throws {
        try assertLayer("Application", forbidsSubstrings: ["UserDefaults"])
    }

    func test_domain_layer_does_not_import_SwiftUI() throws {
        try assertLayer("Domain", forbidsSubstrings: ["import SwiftUI"])
    }

    func test_domain_layer_does_not_use_URLSession() throws {
        try assertLayer("Domain", forbidsSubstrings: ["URLSession"])
    }

    func test_domain_layer_does_not_use_UserDefaults() throws {
        try assertLayer("Domain", forbidsSubstrings: ["UserDefaults"])
    }

    func test_data_layer_does_not_import_SwiftUI() throws {
        try assertLayer("Data", forbidsSubstrings: ["import SwiftUI"])
    }

    // MARK: - Helpers

    private func assertLayer(
        _ layerFolder: String,
        forbidsSubstrings needles: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let layerRoot = try locateLayerRoot(named: layerFolder)
        let files = try swiftFiles(under: layerRoot)
        XCTAssertFalse(files.isEmpty,
                       "Layer \(layerFolder) contains no Swift files — layer root not resolved correctly.",
                       file: file, line: line)

        var offenders: [String] = []
        for url in files {
            let text = try String(contentsOf: url, encoding: .utf8)
            let stripped = stripSwiftComments(from: text)
            for needle in needles where stripped.contains(needle) {
                offenders.append("\(url.lastPathComponent): contains \"\(needle)\" outside of comments")
            }
        }
        XCTAssertTrue(
            offenders.isEmpty,
            "Layer \(layerFolder) has forbidden references:\n- " + offenders.joined(separator: "\n- "),
            file: file, line: line
        )
    }

    /// Removes Swift line comments (`// …` to EOL) and block comments
    /// (`/* … */`, non-nested — sufficient for our own source). Docstrings
    /// starting with `///` are also line comments and are handled by the
    /// `//` case. String literals are NOT preserved specially; if a
    /// forbidden token ever appears inside a string literal that would
    /// also be a legitimate signal to investigate.
    private func stripSwiftComments(from text: String) -> String {
        var out = ""
        var i = text.startIndex
        while i < text.endIndex {
            let c = text[i]
            let next = text.index(after: i)
            if c == "/" && next < text.endIndex && text[next] == "/" {
                // Line comment — skip to newline.
                if let eol = text[i...].firstIndex(of: "\n") {
                    i = eol
                } else {
                    break
                }
            } else if c == "/" && next < text.endIndex && text[next] == "*" {
                // Block comment — skip to */.
                var j = text.index(after: next)
                while j < text.endIndex {
                    let jn = text.index(after: j)
                    if text[j] == "*" && jn < text.endIndex && text[jn] == "/" {
                        i = text.index(after: jn)
                        break
                    }
                    j = text.index(after: j)
                }
                if j >= text.endIndex { break }
            } else {
                out.append(c)
                i = text.index(after: i)
            }
        }
        return out
    }

    /// Walks up from this test file to find `apps/ios/WildLive/<layer>/`.
    /// Assumes the tests are run from the repo checkout (true for local
    /// xcodebuild and CI).
    private func locateLayerRoot(named layer: String) throws -> URL {
        var here = URL(fileURLWithPath: #file, isDirectory: false)
            .deletingLastPathComponent() // WildLiveTests/
            .deletingLastPathComponent() // ios/
        // `here` is now .../apps/ios
        here.append(path: "WildLive")
        here.append(path: layer)

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: here.path, isDirectory: &isDir),
              isDir.boolValue else {
            throw NSError(
                domain: "ArchitectureBoundaryTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                    "Layer folder not found at \(here.path). Update this test if the layout changed."]
            )
        }
        return here
    }

    private func swiftFiles(under root: URL) throws -> [URL] {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        var result: [URL] = []
        for case let url as URL in e where url.pathExtension == "swift" {
            result.append(url)
        }
        return result.sorted { $0.path < $1.path }
    }
}
