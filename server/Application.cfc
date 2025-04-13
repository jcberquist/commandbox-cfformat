component {

    this.name = 'cfformat-server';
    this.mappings['/cfformat'] = expandPath('../');

    function onApplicationStart() {
        var rootFolder = expandPath('../');
        var cftokensVersion = deserializeJSON(fileRead(rootFolder & 'box.json')).cftokens;
        var binFolder = expandPath(rootFolder & 'bin/#cftokensVersion#/');
        application.cfformat = new cfformat.models.CFFormat(binFolder, rootFolder);
    }

    function onRequest(targetPage) {
        if (targetPage != '/index.cfm') {
            cfheader(statuscode = "404");
            return;
        }

        if (cgi.request_method == 'GET') {
            variables.targetPage = targetPage;
            include '/index.cfm';
        } else if (cgi.request_method == 'POST') {
            try {
                if (listFirst(cgi.content_type, ';') != 'application/json') {
                    throw('Content-Type header did not specify `application/json`.')
                }
                var httpRequest = getHTTPRequestData();
                var data = deserializeJSON(httpRequest.content);
                cfcontent(type = "application/json");
                writeOutput(serializeJSON({'text': format(data)}));
            } catch (any e) {
                cfheader(statuscode = "500");
                cfcontent(type = "application/json");
                writeOutput(serializeJSON({'error': e.message}));
            }
        } else {
            cfheader(statuscode = "500");
        }
    }

    private function format(src) {
        var settings = {};

        if (src.keyExists('path')) {
            settings.append(findSettings(src.path));
        }

        if (src.keyExists('settings')) {
            settings.append(src.settings);
        }

        return application.cfformat.formatText(src.text, settings);
    }

    private function findSettings(path) {
        var formatDir = getDirectoryFromPath(path).replace('\', '/', 'all');
        while (formatDir.listLen('/') > 0) {
            var fullPath = formatDir & '.cfformat.json';
            if (fileExists(fullPath)) {
                return deserializeJSON(fileRead(fullPath));
            }
            if (directoryExists(formatDir & '/.git/')) {
                break;
            }
            formatDir = formatDir.listDeleteAt(formatDir.listLen('/'), '/') & '/';
        }
        return {};
    }

}
