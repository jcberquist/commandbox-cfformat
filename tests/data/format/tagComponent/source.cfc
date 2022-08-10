<cfcomponent output="false" accessors="true" extends="does.not.exist">
<cffunction name="test">
<cfargument name="test">
<cfset var mydata = [1,2,"a string of text goes here"]>
<cfset var result = "">
<cfif not arrayLen( mydata )>
<cfhttp url="www.google.com?data=#mydata#" result="result">
</cfif>
<cfreturn result>
</cffunction>
</cfcomponent>
