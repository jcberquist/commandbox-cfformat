<!doctype html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>CFFormat Server</title>
        <style type="text/css">
            body {
                font-family: sans;
                padding: 10px;
                max-width: 800px;
                margin-left: auto;
                margin-right: auto;
            }
            p {
                line-height: 1.75;
            }
            code {
                white-space: nowrap;
                padding: 1px;
                border: 1px solid #ccc;
                border-radius: 4px;
                background-color: #efefef;
            }
            pre {
                padding: 15px;
                border: 1px solid #ccc;
                border-radius: 4px;
                background-color: #efefef;
            }
            textarea {
                width: 100%;
            }
        </style>
    </head>
    <body class="prose mx-auto p-5">
        <cfoutput>
        <h1>CFFormat Server</h1>
        <h2>Server is running at <span>#cgi.http_host#</span></h2>

        <p>
            You can manage this server using the regular CommandBox server commands: for example,
            <code>server start cfformat-server</code> and <code>server stop cfformat-server</code>.
            Run it on a different port: <code>cfformat server port=8888</code> or
            <code>server start cfformat-server port=8888</code>. (The latter will be written to the
            cfformat-server <code>server.json</code>, and thus it will persist through restarts.)
        </p>

        <p>
            This server uses cfformat to format your CFML components. Post JSON containing your
            source code to this server and it will return formatted CFML code. This can be
            integrated with your editor via simple HTTP requests.
        </p>

        <p>The syntax to use is as follows:</p>

<pre>
POST http://#cgi.http_host#

Content-Type: application/json

{
    "text": "",
    "path": "/absolute/path/to/file/being/formatted.cfc",
    "settings": {}
}
</pre>

        <p>
            In the JSON object sent, the key "text" is required, and its value should be the source
            code to format. If you provide a "path", the file tree will be searched upwards to the
            root starting from that path looking for a <code>.cfformat.json</code> settings file,
            which will be used when formatting. (Note that if a <code>.git</code> folder is
            encountered, the search will abort at that directory level.) The path can also be the directory the file will be saved into, in the case of new files. You can provide
            settings directly under the "settings" key; these settings will take precedence over a
            <code>.cfformat.json</code> settings file.
        </p>

        <h3>Try it out:</h3>

        <textarea id="code-box" rows="5">component{function init(){return this;}}</textarea>

        <button type="button" id="format-btn">Format</button>

        <pre id="output-box" style="display: none"></pre>

        </cfoutput>
    </body>

    <script type="text/javascript">
    const codeBox = document.getElementById('code-box');
    const formatBtn = document.getElementById('format-btn');
    const outputBox = document.getElementById('output-box');

    formatBtn.addEventListener('click', event => {
        const text = codeBox.value;
        fetch('/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ text }),
        }).then(res => {
            res.json().then(function (data) {
                outputBox.style.removeProperty('display');
                outputBox.innerHTML = data.text;
            });
        });
    });
    </script>
</html>
