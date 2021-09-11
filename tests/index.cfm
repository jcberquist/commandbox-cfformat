<cfsilent>
<cfscript>
cftokensVersion = deserializeJSON(fileRead(expandPath('/box.json'))).cftokens;
binFolder = expandPath('/bin/#cftokensVersion#/');
executable = new models.CFFormat(binFolder, expandPath('/')).getExecutable();

// generate token json files
cfexecute(
    name = executable,
    arguments = "parse ""#expandPath('/tests/data/')#"" ""#expandPath('/tests/json/')#""",
    timeout = 10,
    variable = "fileArray"
);

param name="url.reporter" default="simple";
param name="url.bundles" default="";
param name="url.directory" default="tests.specs";

param name="url.coverageEnabled" default="false" type="boolean";
param name="url.coveragePathToCapture" default="#expandPath('/models')#";
param name="url.coverageBrowserOutputDir" default="#expandPath('/tests/coverage')#";

testbox = new testbox.system.Testbox(
    options = {
        coverage: {
            enabled: url.coverageEnabled,
            pathToCapture: url.coveragePathToCapture,
            browser: {outputDir: url.coverageBrowserOutputDir}
        }
    }
);

if (len(url.bundles)) {
    testbox.addBundles(url.bundles);
}
if (len(url.directory)) {
    testbox.addDirectories(url.directory);
}

results = testBox.run(reporter = url.reporter);
</cfscript>
</cfsilent>
<cfcontent reset="true">
<cfoutput>#trim(results)#</cfoutput>
