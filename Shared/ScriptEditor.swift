//
//  WebEditor.swift
//  ShaderMania
//
//  Created by Markus Moenig on 25/8/20.
//

struct CompileError
{
    var asset           : Asset? = nil
    var line            : Int32? = nil
    var column          : Int32? = 0
    var error           : String? = nil
    var type            : String = "error"
}

#if !os(tvOS)

import SwiftUI
import WebKit
import Combine

class ScriptEditor
{
    var webView         : WKWebView
    var game            : Game
    var sessions        : Int = 0
    var colorScheme     : ColorScheme
    
    var helpText        : String = ""
    
    init(_ view: WKWebView, _ game: Game,_ colorScheme: ColorScheme)
    {
        self.webView = view
        self.game = game
        self.colorScheme = colorScheme
        
        if let asset = game.assetFolder.getAsset("Final", .Shader) {
            game.assetFolder.select(asset.id)
            createSession(asset)
            setTheme(colorScheme)
        }
        
        createHelpSession()
    }
    
    func createHelpSession()
    {
        guard let path = Bundle.main.path(forResource: "help", ofType: "cpp", inDirectory: "Files") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            helpText = value
        }
        
        webView.evaluateJavaScript(
            """
            var helpSession = ace.createEditSession(``)
            helpSession.setMode("ace/mode/c_cpp");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func activateHelpSession()
    {
        game.showingHelp = true
        webView.evaluateJavaScript(
            """
            helpSession.setValue(`\(helpText)`)
            editor.setSession(helpSession)
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setTheme(_ colorScheme: ColorScheme)
    {
        let theme: String
        if colorScheme == .light {
            theme = "tomorrow"
        } else {
            theme = "tomorrow_night"
        }
        webView.evaluateJavaScript(
            """
            editor.setTheme("ace/theme/\(theme)");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil)
    {
        if asset.scriptName.isEmpty {
            asset.scriptName = "session" + String(sessions)
            sessions += 1
        }

        if asset.type == .Shader || asset.type == .Common || asset.type == .Buffer {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/c_cpp");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        } else
        if asset.type == .Image || asset.type == .Audio || asset.type == .Texture {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/text");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        }
    }
    
    func setReadOnly(_ readOnly: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setReadOnly(\(readOnly));
            """, completionHandler: { (value, error) in
         })
    }
    
    func setSilentMode(_ silent: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setOptions({
                cursorStyle: \(silent ? "'wide'" : "'ace'") // "ace"|"slim"|"smooth"|"wide"
            });
            """, completionHandler: { (value, error) in
         })
    }
    
    func getAssetValue(_ asset: Asset,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            \(asset.scriptName).getValue()
            """, completionHandler: { (value, error) in
                if let value = value as? String {
                    cb(value)
                }
         })
    }
    
    func setAssetValue(_ asset: Asset, value: String)
    {
        let cmd = """
        \(asset.scriptName).setValue(`\(value)`)
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setAssetSession(_ asset: Asset)
    {
        game.showingHelp = false
        func setSession()
        {
            let cmd = """
            editor.setSession(\(asset.scriptName))
            """
            webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
            })
        }
        
        if asset.scriptName.isEmpty == true {
            createSession(asset, { () in
                setSession()
            })
        } else {
            setSession()
        }

    }
    
    func setError(_ error: CompileError, scrollToError: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations([{
            row: \(error.line!-1),
            column: \(error.column!),
            text: "\(error.error!)",
            type: "error" // also warning and information
            }]);

            \(scrollToError == true ? "editor.scrollToLine(\(error.line!-1), true, true, function () {});" : "")

            """, completionHandler: { (value, error ) in
         })
    }
    
    func setErrors(_ errors: [CompileError])
    {
        var str = "["
        for error in errors {
            str +=
            """
            {
                row: \(error.line!),
                column: \(error.column!),
                text: \"\(error.error!)\",
                type: \"\(error.type)\"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setFailures(_ lines: [Int32])
    {
        var str = "["
        for line in lines {
            str +=
            """
            {
                row: \(line),
                column: 0,
                text: "Failed",
                type: "error"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func getSessionCursor(_ cb: @escaping (Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.getCursorPosition().row
            """, completionHandler: { (value, error ) in
                if let v = value as? Int32 {
                    cb(v)
                }
         })
    }
    
    func getChangeDelta(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            delta
            """, completionHandler: { (value, error ) in
                //print(value)
                if let map = value as? [String:Any] {
                    var from : Int32 = -1
                    var to   : Int32 = -1
                    if let f = map["start"] as? [String:Any] {
                        if let ff = f["row"] as? Int32 {
                            from = ff
                        }
                    }
                    if let t = map["end"] as? [String:Any] {
                        if let tt = t["row"] as? Int32 {
                            to = tt
                        }
                    }
                    cb(from, to)
                }
         })
    }
    
    func clearAnnotations()
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().clearAnnotations()
            """, completionHandler: { (value, error ) in
         })
    }
    
    func updated()
    {
        if let asset = game.assetFolder.current {
            getAssetValue(asset, { (value) in
                self.game.assetFolder.assetUpdated(id: asset.id, value: value)
                //self.getChangeDelta({ (from, to) in
                //    self.game.assetFolder.assetUpdated(id: asset.id, value: value, deltaStart: from, deltaEnd: to)
                //})
            })
        }
    }
}

class WebViewModel: ObservableObject {
    @Published var didFinishLoading: Bool = false
    
    init () {
    }
}

#if os(OSX)
struct SwiftUIWebView: NSViewRepresentable {
    public typealias NSViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game        : Game
        private var colorScheme : ColorScheme

        init(_ game: Game,_ colorScheme: ColorScheme) {
            self.game = game
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = game.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            game.scriptEditor = ScriptEditor(web, game, colorScheme)
            web.isHidden = false
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
#else
struct SwiftUIWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game        : Game
        private var colorScheme : ColorScheme
        
        init(_ game: Game,_ colorScheme: ColorScheme) {
            self.game = game
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = game.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            game.scriptEditor = ScriptEditor(web, game, colorScheme)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct WebView  : View {
    var game        : Game
    var colorScheme : ColorScheme

    init(_ game: Game,_ colorScheme: ColorScheme) {
        self.game = game
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        SwiftUIWebView(game: game, colorScheme: colorScheme)
    }
}

#else

class ScriptEditor
{
    var mapHelpText     : String = "## Available:\n\n"
    var behaviorHelpText: String = "## Available:\n\n"
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil) {}
    
    func setAssetValue(_ asset: Asset, value: String) {}
    func setAssetSession(_ asset: Asset) {}
    
    func setError(_ error: CompileError, scrollToError: Bool = false) {}
    func setErrors(_ errors: [CompileError]) {}
    func clearAnnotations() {}
    
    func getSessionCursor(_ cb: @escaping (Int32)->() ) {}
    
    func setReadOnly(_ readOnly: Bool = false) {}
    func setDebugText(text: String) {}
    
    func setFailures(_ lines: [Int32]) {}
    
    func getBehaviorHelpForKey(_ key: String) -> String? { return nil }
    func getMapHelpForKey(_ key: String) -> String? { return nil }
}

#endif
