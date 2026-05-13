// qMD - HTML template builder
// Builds the complete HTML template with inlined JS/CSS for WKWebView rendering.
// Note: innerHTML is used intentionally for local markdown rendering.
// This is a local desktop app that only renders user-owned .md files from disk.

import Foundation

struct HTMLTemplate {
    let html: String

    init() {
        let markdownItJS = Self.loadResource("markdown-it.min", ext: "js")
        let highlightJS = Self.loadResource("highlight.min", ext: "js")
        let highlightDarkCSS = Self.loadResource("github-dark.min", ext: "css")
        let highlightLightCSS = Self.loadResource("github.min", ext: "css")
        let customCSS = Self.loadResource("style", ext: "css")

        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style media="(prefers-color-scheme: dark)">\(highlightDarkCSS)</style>
            <style media="(prefers-color-scheme: light)">\(highlightLightCSS)</style>
            <style>\(customCSS)</style>
        </head>
        <body>
            <div id="content"></div>
            <script>\(markdownItJS)</script>
            <script>\(highlightJS)</script>
            <script>
            var md = window.markdownit({
                html: true,
                linkify: true,
                typographer: true,
                highlight: function(str, lang) {
                    if (lang && hljs.getLanguage(lang)) {
                        try { return hljs.highlight(str, {language: lang}).value; }
                        catch (e) {}
                    }
                    return '';
                }
            });

            function decodeBase64UTF8(b64) {
                var bytes = Uint8Array.from(atob(b64), function(c) {
                    return c.charCodeAt(0);
                });
                return new TextDecoder('utf-8').decode(bytes);
            }

            function renderMarkdown(base64, preserveScroll) {
                var savedScroll = preserveScroll ? window.scrollY : 0;
                var text = decodeBase64UTF8(base64);
                var rendered = md.render(text);
                rendered = rendered.replace(/<li><p>\\[x\\]/gi,
                    '<li class="task-item checked"><p><input type="checkbox" checked disabled> ');
                rendered = rendered.replace(/<li><p>\\[ \\]/g,
                    '<li class="task-item"><p><input type="checkbox" disabled> ');
                rendered = rendered.replace(/<li>\\[x\\]/gi,
                    '<li class="task-item checked"><input type="checkbox" checked disabled> ');
                rendered = rendered.replace(/<li>\\[ \\]/g,
                    '<li class="task-item"><input type="checkbox" disabled> ');
                var el = document.getElementById('content');
                el.textContent = '';
                el.insertAdjacentHTML('afterbegin', rendered);
                window.scrollTo(0, savedScroll);
            }

            var currentMatchIndex = -1;
            var matchElements = [];

            function highlightSearch(query) {
                clearSearch();
                if (!query) return;
                var content = document.getElementById('content');
                var walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, null, false);
                var textNodes = [];
                while (walker.nextNode()) textNodes.push(walker.currentNode);
                var lowerQuery = query.toLowerCase();
                textNodes.forEach(function(node) {
                    var text = node.textContent;
                    var lowerText = text.toLowerCase();
                    var idx = lowerText.indexOf(lowerQuery);
                    if (idx === -1) return;
                    var frag = document.createDocumentFragment();
                    var lastIdx = 0;
                    while (idx !== -1) {
                        frag.appendChild(document.createTextNode(text.substring(lastIdx, idx)));
                        var mark = document.createElement('mark');
                        mark.className = 'search-match';
                        mark.textContent = text.substring(idx, idx + query.length);
                        frag.appendChild(mark);
                        lastIdx = idx + query.length;
                        idx = lowerText.indexOf(lowerQuery, lastIdx);
                    }
                    frag.appendChild(document.createTextNode(text.substring(lastIdx)));
                    node.parentNode.replaceChild(frag, node);
                });
                matchElements = document.querySelectorAll('.search-match');
                currentMatchIndex = -1;
                if (matchElements.length > 0) nextMatch();
            }

            function clearSearch() {
                document.querySelectorAll('.search-match').forEach(function(el) {
                    el.classList.remove('search-current');
                    var parent = el.parentNode;
                    parent.replaceChild(document.createTextNode(el.textContent), el);
                    parent.normalize();
                });
                matchElements = [];
                currentMatchIndex = -1;
            }

            function nextMatch() {
                if (matchElements.length === 0) return 0;
                if (currentMatchIndex >= 0 && currentMatchIndex < matchElements.length)
                    matchElements[currentMatchIndex].classList.remove('search-current');
                currentMatchIndex = (currentMatchIndex + 1) % matchElements.length;
                matchElements[currentMatchIndex].classList.add('search-current');
                matchElements[currentMatchIndex].scrollIntoView({block: 'center', behavior: 'smooth'});
                return matchElements.length;
            }

            function prevMatch() {
                if (matchElements.length === 0) return 0;
                if (currentMatchIndex >= 0 && currentMatchIndex < matchElements.length)
                    matchElements[currentMatchIndex].classList.remove('search-current');
                currentMatchIndex = (currentMatchIndex - 1 + matchElements.length) % matchElements.length;
                matchElements[currentMatchIndex].classList.add('search-current');
                matchElements[currentMatchIndex].scrollIntoView({block: 'center', behavior: 'smooth'});
                return matchElements.length;
            }
            </script>
        </body>
        </html>
        """
    }

    private static func loadResource(_ name: String, ext: String) -> String {
        if let str = ResourceLoader.string(forResource: name, ext: ext, subdirectory: "web") {
            return str
        }
        if let str = ResourceLoader.string(forResource: name, ext: ext, subdirectory: "Resources/web") {
            return str
        }
        if let str = ResourceLoader.string(forResource: name, ext: ext) {
            return str
        }
        return "/* Resource not found: \(name).\(ext) */"
    }
}
