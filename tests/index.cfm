<cfsilent>
<cfscript>
isWindows = createObject( 'java', 'java.lang.System' )
    .getProperty( 'os.name' )
    .lcase()
    .contains( 'win' );
binary = isWindows ? 'cftokens.exe' : 'cftokens_osx';
cftokensVersion = deserializeJSON( fileRead( expandPath( '/box.json' ) ) ).cftokens;

// generate token json files
cfexecute(
    name=expandPath( '/bin/#cftokensVersion#/#binary#' ),
    arguments='"#expandPath( '/tests/data/' )#" "#expandPath( '/tests/json/' )#"',
    timeout=10,
    variable='fileArray'
);

testbox = new testbox.system.Testbox();
param name="url.reporter" default="simple";
param name="url.directory" default="tests.specs";
args = { reporter: url.reporter, directory: url.directory };
if ( structKeyExists( url, 'bundles' ) ) args.bundles = url.bundles;
results = testBox.run( argumentCollection = args );
</cfscript>
</cfsilent>
<cfcontent reset="true">
<cfoutput>#trim( results )#</cfoutput>
