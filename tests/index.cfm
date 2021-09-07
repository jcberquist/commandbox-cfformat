<cfsilent>
<cfscript>
cftokensVersion = deserializeJSON(fileRead(expandPath('/box.json'))).cftokens;
binFolder = expandPath('/bin/#cftokensVersion#/');
executable = new models.CFFormat(binFolder, expandPath('/')).getExecutable();

// generate token json files
cfexecute(
    name=executable,
    arguments='parse "#expandPath('/tests/data/')#" "#expandPath('/tests/json/')#"',
    timeout=10,
    variable='fileArray'
);

testbox = new testbox.system.Testbox(
    options: {
        coverage: {
            blacklist: "tests,testbox",
            browser: {
                outputDir: "#ExpandPath('.')#/coverage"
            }
        }
    }
);
param name="url.reporter" default="simple";
param name="url.directory" default="tests.specs";
args = {reporter: url.reporter, directory: url.directory};
if (structKeyExists(url, 'bundles')) args.bundles = url.bundles;
results = testBox.run(argumentCollection = args);
</cfscript>
</cfsilent>
<cfcontent reset="true">
<cfoutput>#trim(results)#</cfoutput>
