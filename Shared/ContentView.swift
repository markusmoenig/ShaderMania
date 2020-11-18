//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 19/11/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ShaderManiaDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(ShaderManiaDocument()))
    }
}
