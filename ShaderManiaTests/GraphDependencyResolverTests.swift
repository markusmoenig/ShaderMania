//
//  GraphDependencyResolverTests.swift
//  ShaderManiaTests
//
//  Created by Codex on 30/4/26.
//

import XCTest
@testable import ShaderManiaCore

final class GraphDependencyResolverTests: XCTestCase {

    func testCollectsDependenciesBeforeDependentNode() {
        let output = UUID()
        let source = UUID()
        let texture = UUID()
        let graph = [
            output: [source, texture],
            source: [texture],
            texture: []
        ]

        let result = GraphDependencyResolver.collect(start: output) { graph[$0] ?? [] }

        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertEqual(result.ordered, [texture, source, output])
    }

    func testCycleIsReportedWithoutInfiniteRecursion() {
        let first = UUID()
        let second = UUID()
        let graph = [
            first: [second],
            second: [first]
        ]

        let result = GraphDependencyResolver.collect(start: first) { graph[$0] ?? [] }

        XCTAssertEqual(result.issues, [.cycle(first)])
        XCTAssertEqual(Set(result.ordered), Set([first, second]))
    }

    func testSelfCycleIsReported() {
        let node = UUID()
        let graph = [
            node: [node]
        ]

        let result = GraphDependencyResolver.collect(start: node) { graph[$0] ?? [] }

        XCTAssertEqual(result.issues, [.cycle(node)])
        XCTAssertEqual(result.ordered, [node])
    }

    func testSharedDependencyIsOnlyCollectedOnce() {
        let output = UUID()
        let left = UUID()
        let right = UUID()
        let shared = UUID()
        let graph = [
            output: [left, right],
            left: [shared],
            right: [shared],
            shared: []
        ]

        let result = GraphDependencyResolver.collect(start: output) { graph[$0] ?? [] }

        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertEqual(result.ordered.filter { $0 == shared }.count, 1)
        XCTAssertEqual(result.ordered.last, output)
    }
}
