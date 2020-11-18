//
//  ShaderManiaApp.swift
//  Shared
//
//  Created by Markus Moenig on 19/11/20.
//

import SwiftUI

@main
struct ShaderManiaApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ShaderManiaDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
