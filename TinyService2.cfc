<!---
* @file  TinifyService2.cfc
* @author  Denard Springle (denard.springle@gmail.com)
* @description This is a CFML wrapper for the TinyPng.com API
--->

<cfcomponent output="false" displayname="tinify" accessors="true">
	<cfproperty name="apiKey" type="string" />
	<cfproperty name="baseURI" type="string" />
	<cfproperty name="userAgent" type="string" />

	<cffunction name="init" returntype="any" access="public">
		<cfargument name="apiKey" type="string" required="true" />
		<cfargument name="baseURI" type="string" required="false" default="https://api.tinify.com" />

		<cfset setApiKey(arguments.apiKey) />
		<cfset setBaseURI(arguments.baseURI) />

		<cfset variables.product = server.coldfusion.productname />
		<cfif findNoCase( 'lucee', variables.product )>
			<cfset variables.version = server.lucee.version />
		<cfelseif findNoCase( 'railo', variables.product )>
			<cfset variables.version = server.railo.version />
		<cfelse>
			<cfset variables.version = listFirst( server.coldfusion.productversion ) />
		</cfif>

		<cfset setUserAgent('Tinify/1.0/ColdFusion/#variables.version# (CFML Engine)') />

		<cfreturn this />
	</cffunction>

	<cffunction name="shrink" returntype="any" access="public" displayname="shrink" description="I shrink a local or remote file using the Tinify API">
		<cfargument name="filePath" type="string" required="false" default="" hint="I am the expanded path to the local image file to compress" />
		<cfargument name="url" type="string" required="false" default="" hint="I am the the FQDN URL to the remote image file to compress" />
		<cfargument name="returnType" type="string" required="false" default="file" hint="I determine if the image itself is returned or the JSON struct response" />
		<cfargument name="method" type="string" required="false" default="scale" hint="I am the resize method to use if resize is desired (one of: scale, fit or cover)" />
		<cfargument name="height" type="numeric" required="false" default="0" hint="I determine the height of the rezised image (required for fit or cover)" />
		<cfargument name="width" type="numeric" required="false" default="0" hint="I determine the width of the resized image (required for fit or cover)" />

		<cfset local.endpoint = "/shrink" />
		<cfset local.result = "" />
		<cfset local.options = "" />

		<!--- check if we're requesting a local file --->
		<cfif( len( trim( arguments.filePath ) ) )>
			<!--- we are, do the API call passing the local file path --->
			<cfset local.result = doApiCall( endpoint = local.endpoint, filePath = arguments.filePath ) />
			<!--- otherwise --->
		<cfelse>
			<!--- we're requesting compression of a remote file, do the API call passing the url of the remote file --->
			<cfset local.result = doApiCall( endpoint = local.endpoint, url = arguments.url ) />
		</cfif>

		<!--- check if we're requesting a resize at the same time --->
		<cfif( len( trim( arguments.method ) ) and ( arguments.height gt 0 or arguments.width gt 0 ) )>
			<!--- we are, set the resize option --->
			<cfset local.options = '{ "resize": { "method": "' & arguments.method & '"' />
			<!--- check if we've passed width --->
			<cfif( arguments.width gt 0 )>
				<!--- we have, set the width in the rezise options --->
				<cfset local.options = local.options & ', "width": ' & arguments.width />
			</cfif>
			<!--- check if we've passed height --->
			<cfif( arguments.height gt 0 )>
				<!--- we have, set the height in the resize options --->
				<cfset local.options = local.options & ', "height": ' & arguments.height />
			</cfif>
			<cfset local.options = options & ' } }' />
		</cfif>

		<!--- check if we're returning the image file and not the struct data --->
		<cfif( arguments.returnType eq 'file' and structKeyExists( local.result, 'location' ) )>
			<!--- return the image data from the location, passing any resize options --->
			<cfreturn getImageData( url = local.result.location, options = local.options ) />
		</cfif>

		<!--- check that we didn't have any errors and have an image location to fetch --->
		<cfif( structKeyExists( result, 'location') )>
			<!--- get the image data as part of the returned struct --->
			<cfset local.result.imageData = getImageData( url = local.result.location, options = local.options ) />
		</cfif>

		<!--- return the struct instead --->
		<cfreturn local.result />
	</cffunction>

	<cffunction name="doApiCall" returntype="struct" access="private" displayname="doApiCall" description="I make the call to the Tinify API and return struct of results">
		<cfargument name="endpoint" type="string" required="false" hint="I am the constructed endpoint URL" />
		<cfargument name="filePath" type="string" required="false" default="" hint="I am the expanded path to the local image file to compress" />
		<cfargument name="url" type="string" required="false" default="" hint="I am the the FQDN URL to the remote image file to compress" />

		<cfset local.result = "" />
		<cfset local.sourceImage = "" />
		<cfset local.returnStruct = {} />

		<!--- configure the service --->
		<cfhttp url="#getBaseURI()##arguments.endpoint#" method="post" result="local.result" useragent="#getUserAgent()#" charset="utf-8">
			<cfhttpparam type="header" name="Authorization" value="Basic #toBase64( 'api:' & getApiKey())#" />
			<!--- check if we're sending a local file request --->
			<cfif len(trim(arguments.filePath))>
				<!--- we are, get the local file as an image --->
				<cffile action="readbinary" file="#arguments.filePath#" variable="local.sourceImage" />
				<!--- and set the image in the body of the request as binary data --->
				<cfhttpparam type="body" value="#local.sourceImage#" />
			<cfelse>
				<cfhttpparam type="header" name="Content-Type" value='application/json' />
				<!--- and send the json in the body of the request --->
				<cfhttpparam type="body" value='{"source": {"url": "#arguments.url#"} }' />
			</cfif>
		</cfhttp>

		<!--- check if the status code is in the 200's --->
		<cfif( local.result.Responseheader.status_code lt 300 )>
			<!--- it is, get the header location --->
			<cfset local.returnStruct.location = local.result.responseHeader[ 'Location' ] />
			<!--- get the compression count --->
			<cfset local.returnStruct.compCount = local.result.responseHeader[ 'Compression-Count' ] />
			<!--- get the details of the compressed image --->
			<cfset local.returnStruct.details = deserializeJSON( local.result.fileContent ) />
		<cfelse>
			<!--- an error occurred, get the details of the error --->
			<cfset local.returnStruct.details = deserializeJSON( local.result.fileContent ) />
		</cfif>

		<cfreturn local.returnStruct />
	</cffunction>

	<cffunction name="getImageData" returntype="any" access="private" displayname="getImageData" description="I grab the image data from the API">
		<cfargument name="url" type="string" required="true" hint="I am the the FQDN URL to the compressed image file" />
		<cfargument name="options" type="string" required="false" hint="I am the JSON to send for resize requests" />

		<cfhttp url="#arguments.url#" method="#len(trim(arguments.options)) ? 'post' : 'get'#" result="local.result" useragent="#getUserAgent()#" charset="utf-8" getasbinary="yes">
			<cfhttpparam type="header" name="Authorization" value="Basic #toBase64( 'api:' & getApiKey())#" />

			<cfif len(trim(arguments.options))>
				<cfhttpparam type="header" name="Content-Type" value="application/json" />
				<cfhttpparam type="body" value="#arguments.options#" />
			</cfif>
		</cfhttp>

		<!--- check if the status code is in the 200's --->
		<cfif( local.result.Responseheader.status_code lt 300 )>
			<!--- it is, generate an image from the file content (to render you have to use <cfimage action="writeTobrowser" />) --->
			<cfreturn ImageNew(local.result.filecontent) />
		<cfelse>
			<!--- an error occurred, return the details of the error --->
			<cfreturn deserializeJSON( local.result.fileContent ) />
		</cfif>
	</cffunction>
</cfcomponent>
