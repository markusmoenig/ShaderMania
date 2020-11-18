define("ace/snippets/denrim",["require","exports","module"],function(e,t,n){"use strict";t.snippetText="snippet >\ndescription function\nscope denrim\n    -> ${1}() = ${2};\n\nsnippet >\ndescription if\nscope denrim\n    -> struct ${1} \\{ ${2:**} \\n \\}\n",t.scope="denrim"});                (function() {
                    window.require(["ace/snippets/denrim"], function(m) {
                        if (typeof module == "object" && typeof exports == "object" && module) {
                            module.exports = m;
                        }
                    });
                })();
            