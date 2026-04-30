//
//  ShaderAnnotationScanner.swift
//  ShaderMania
//
//  Created by Codex on 30/4/26.
//

import Foundation

struct ShaderAnnotation {
    let type: String
    let parameters: [String: String]
    let range: Range<String.Index>
}

enum ShaderAnnotationScanResult {
    case annotation(ShaderAnnotation)
    case malformed(type: String, range: Range<String.Index>, message: String)
}

enum ShaderAnnotationScanner {
    
    static func next(in line: String, types: [String]) -> ShaderAnnotationScanResult? {
        let matches = types.compactMap { type -> (type: String, range: Range<String.Index>)? in
            guard let range = line.range(of: type) else {
                return nil
            }
            return (type, range)
        }
        .sorted { $0.range.lowerBound < $1.range.lowerBound }
        
        guard let match = matches.first else {
            return nil
        }
        
        guard match.range.upperBound < line.endIndex, line[match.range.upperBound] == "<" else {
            return .malformed(type: match.type, range: match.range, message: "\(match.type) is missing '<'.")
        }
        
        let parameterStart = line.index(after: match.range.upperBound)
        guard let close = line[parameterStart...].firstIndex(of: ">") else {
            return .malformed(type: match.type, range: match.range, message: "\(match.type) is missing '>'.")
        }
        
        let parameterText = String(line[parameterStart..<close])
        let end = line.index(after: close)
        let annotation = ShaderAnnotation(
            type: match.type,
            parameters: splitParameters(parameterText),
            range: match.range.lowerBound..<end
        )
        return .annotation(annotation)
    }
    
    static func splitParameters(_ parameters: String) -> [String: String] {
        var result: [String: String] = [:]
        
        for parameter in parameters.split(separator: ",") {
            guard let separator = parameter.firstIndex(of: ":") else {
                continue
            }
            
            let key = parameter[..<separator].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let valueStart = parameter.index(after: separator)
            let value = parameter[valueStart...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
            
            if key.isEmpty == false {
                result[key] = value
            }
        }
        
        return result
    }
}
