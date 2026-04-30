//
//  GraphDependencyResolver.swift
//  ShaderMania
//
//  Created by Codex on 30/4/26.
//

import Foundation

enum GraphDependencyIssue: Equatable {
    case cycle(UUID)
}

enum GraphDependencyResolver {

    static func collect(start: UUID, dependenciesFor: (UUID) -> [UUID]) -> (ordered: [UUID], issues: [GraphDependencyIssue]) {
        var ordered: [UUID] = []
        var visited: Set<UUID> = []
        var visiting: Set<UUID> = []
        var issues: [GraphDependencyIssue] = []

        func visit(_ id: UUID) {
            if visiting.contains(id) {
                issues.append(.cycle(id))
                return
            }

            if visited.contains(id) {
                return
            }

            visiting.insert(id)

            for dependency in dependenciesFor(id) {
                visit(dependency)
            }

            visiting.remove(id)
            visited.insert(id)

            if ordered.contains(id) == false {
                ordered.append(id)
            }
        }

        visit(start)

        return (ordered, issues)
    }
}
