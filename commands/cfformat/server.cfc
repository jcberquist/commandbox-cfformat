/**
 * Starts a server that uses cfformat to format source code.
 *
 * {code:bash}
 * cfformat server
 * cfformat server port=8001
 * {code}
 *
 * The default port is 8001. A sample request would look like this:
 *
 * {code}
 * POST http://localhost:8001
 * Content-Type: application/json
 *
 * {"text": "component {}", "path": "/path/to/file.cfc", "settings": {}}
 * {code}
 *
 * The "text" key is required, and its value should be the source code to format.
 * The other keys are optional and are used to determine the .cfformat.json
 * settings to use when formatting.
 *
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property name="serverService" inject="ServerService";
    property name="filesystemUtil" inject="FileSystem";

    /**
     * @port component or directory path
     */
    function run(numeric port = 8001) {
        var path = filesystemutil.resolvepath(cfformat.getRootFolder() & 'server/');
        return serverService.start(serverProps = {directory: path, port: port, saveSettings: false});
    }

}
