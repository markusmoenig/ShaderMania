//
//  ShaderAnnotationScannerTests.swift
//  ShaderManiaTests
//
//  Created by Codex on 30/4/26.
//

import XCTest
@testable import ShaderManiaCore

final class ShaderAnnotationScannerTests: XCTestCase {
    
    func testFindsFloatParameterAndSplitsValues() {
        let line = #"float scale = ParamFloat<UI: "Slider", name: "Scale", min: 0.1, max: 30, default: 15>"#
        
        guard case .annotation(let annotation) = ShaderAnnotationScanner.next(in: line, types: ["ParamFloat"]) else {
            return XCTFail("Expected ParamFloat annotation")
        }
        
        XCTAssertEqual(annotation.type, "ParamFloat")
        XCTAssertEqual(annotation.parameters["ui"], "Slider")
        XCTAssertEqual(annotation.parameters["name"], "Scale")
        XCTAssertEqual(annotation.parameters["min"], "0.1")
        XCTAssertEqual(annotation.parameters["max"], "30")
        XCTAssertEqual(annotation.parameters["default"], "15")
    }
    
    func testFindsEarliestAnnotationAcrossTypes() {
        let line = #"ParamUrl<name: "Video", url: "example.com"> float scale = ParamFloat<name: "Scale">"#
        
        guard case .annotation(let annotation) = ShaderAnnotationScanner.next(in: line, types: ["ParamFloat", "ParamUrl"]) else {
            return XCTFail("Expected annotation")
        }
        
        XCTAssertEqual(annotation.type, "ParamUrl")
        XCTAssertEqual(annotation.parameters["name"], "Video")
        XCTAssertEqual(annotation.parameters["url"], "example.com")
    }
    
    func testMalformedAnnotationWithoutClosingBracketDoesNotTrap() {
        let line = #"float scale = ParamFloat<name: "Scale""#
        
        guard case .malformed(let type, _, let message) = ShaderAnnotationScanner.next(in: line, types: ["ParamFloat"]) else {
            return XCTFail("Expected malformed annotation")
        }
        
        XCTAssertEqual(type, "ParamFloat")
        XCTAssertTrue(message.contains("missing '>'"))
    }
    
    func testMalformedAnnotationWithoutOpeningBracketDoesNotTrap() {
        let line = #"float scale = ParamFloat name: "Scale">"#
        
        guard case .malformed(let type, _, let message) = ShaderAnnotationScanner.next(in: line, types: ["ParamFloat"]) else {
            return XCTFail("Expected malformed annotation")
        }
        
        XCTAssertEqual(type, "ParamFloat")
        XCTAssertTrue(message.contains("missing '<'"))
    }
}
