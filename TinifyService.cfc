/**
*
* @file  TinifyService.cfc
* @author  Denard Springle (denard.springle@gmail.com)
* @description This is a CFML wrapper for the TinyPng.com API
*
*/

component output="false" displayname="tinify" accessors="true" {

	property apiKey;
	property baseURI;
	property userAgent;

	public function init( string apiKey = '', string baseURI = 'https://api.tinify.com' ) {
		setApiKey( arguments.apiKey );
		setBaseURI( arguments.baseURI );

		variables.product = server.coldfusion.productname;

		if( findNoCase( 'lucee', variables.product ) ) {
			variables.version = server.lucee.version;
		} else if( findNoCase( 'railo', variables.product ) ) {
			variables.version = server.railo.version;			
		} else {
			variables.version = listFirst( server.coldfusion.productversion );
		}

		setUserAgent( 'Tinify/1.0/' & variables.product & '/' & variables.version & ' (CFML Engine)' );
		
		return this;
	}

	/**
	* @displayname	shrink
	* @description	I shrink a local or remote file using the Tinify API
	* @param 		filePath {String} I am the expanded path to the local image file to compress
	* @param 		url {String} I am the the FQDN URL to the remote image file to compress
	* @param 		returnType {String} default: file. I determine if the image itself is returned or the JSON struct response
	* @param 		method {String} I am the resize method to use if resize is desired (one of: scale, fit or cover)
	* @param 		height {Numeric} default: 0. I determine the height of the rezised image (required for fit or cover)
	* @param 		width {Numeric} default: 0. I determine the width of the resized image (required for fit or cover)
	* @return		any
	*/
	public any function shrink( 
		string filePath = '', 
		string url = '', 
		string returnType = 'file', 
		string method = '', 
		numeric height = 0, 
		numeric width = 0 
		) {

		// var scope
		var endpoint = '/shrink';
		var result = '';
		var options = '';

		// check if we're requesting a local file
		if( len( trim( arguments.filePath ) ) ) {
			// we are, do the API call passing the local file path
			result = doApiCall( endpoint = endpoint, filePath = arguments.filePath );
		// otherwise
		} else {
			// we're requesting compression of a remote file, do the API call passing the url of the remote file
			result = doApiCall( endpoint = endpoint, url = arguments.url );
		}

		// check if we're requesting a resize at the same time
		if( len( trim( arguments.method ) ) and ( arguments.height gt 0 or arguments.width gt 0 ) ) {
			// we are, set the resize option
			options = '{ "resize": { "method": "' & arguments.method & '"';
			// check if we've passed width
			if( arguments.width gt 0 ) {
				// we have, set the width in the rezise options
				options = options & ', "width": ' & arguments.width;
			}
			//check if we've passed height
			if( arguments.height gt 0 ) {
				// we have, set the height in the resize options
				options = options & ', "height": ' & arguments.height;
			}
			options = options & ' } }';
		}

		// check if we're returning the image file and not the struct data
		if( arguments.returnType eq 'file' and structKeyExists( result, 'location' ) ) {

			// return the image data from the location, passing any resize options
			return getImageData( url = result.location, options = options );
		}

		// check that we didn't have any errors and have an image location to fetch
		if( structKeyExists( result, 'location') ) {

			// get the image data as part of the returned struct
			result.imageData = getImageData( url = result.location, options = options );

		}

		// return the struct instead
		return result;

	}

	/**
	* @displayname	doApiCall
	* @description	I make the call to the Tinify API and return struct of results
	* @param		required endpoint {String} I am the constructed endpoint URL
	* @param 		filePath {String} I am the expanded path to the local image file to compress
	* @param 		url {String} I am the the FQDN URL to the remote image file to compress
	* @return		struct
	*/
	private struct function doApiCall( 
		required string endpoint, 
		string filePath = '', 
		string url = '' 
		) {

		// get a new http service
		var httpService = new http();
		var result = '';
		var sourceImage = '';
		var returnStruct = {};

		// configure the service
		httpService.setMethod( 'post' ); 
		httpService.setUrl( getBaseURI() & arguments.endpoint );
		httpService.setUserAgent( getUserAgent() );

		// add the HTTP Basic Auth header
		httpService.addParam( type = 'header', name = 'Authorization', value = 'Basic ' & toBase64( 'api:' & getApiKey() ) );

		// check if we're sending a local file request
		if( len( trim( arguments.filePath ) ) ) {
			// we are, get the local file as an image
			cfimage( source="#arguments.filePath#", name="sourceImage");
			// and set the image in the body of the request as binary data
			httpService.addParam( type = 'body', value = toBinary( sourceImage ) );
		// otherwise
		} else {
			// we're sending a remote file request, set the charset
			httpService.setCharset( 'utf-8' );
			// and the content-type to json
			httpService.addParam( type = 'header', name='Content-Type', value = 'application/json' );
			// and send the json in the body of the request
			httpService.addParam( type = 'body', value = '{"source": {"url": "' & arguments.url & '"} }' );
		}

		// send the http request and get the result
		result = httpService.send().getPrefix();

		// check if the status code is in the 200's
		if( result.statusCode lt 300 ) {
			// it is, get the header location
			returnStruct.location = result.responseHeader[ 'Location' ];
			// get the compression count
			returnStruct.compCount = result.responseHeader[ 'Compression-Count' ];
			// get the details of the compressed image
			returnStruct.details = deserializeJSON( result.fileContent );
		// otherwise
		} else {
			// an error occurred, get the details of the error
			returnStruct.details = deserializeJSON( result.fileContent );
		}

		// return the structure data
		return returnStruct;

	}


	/**
	* @displayname	getImageData
	* @description	I grab the image data from the API
	* @param 		required url {String} I am the the FQDN URL to the compressed image file
	* @param 		options {String} I am the JSON to send for resize requests
	* @return		any
	*/
	private any function getImageData( 
		required string url, 
		string options = '' 
		) {

		// get a new http service
		var httpService = new http();
		var result = '';

		// configure the service
		httpService.setMethod( 'get' ); 
		httpService.setUrl( arguments.url );
		httpService.setUserAgent( getUserAgent() );

		// add the HTTP Basic Auth header
		httpService.addParam( type = 'header', name = 'Authorization', value = 'Basic ' & toBase64( 'api:' & getApiKey() ) );

		// check if we're passing resize options
		if( len( trim( arguments.options ) ) ) {
			// we are, set the charset
			httpService.setCharset( 'utf-8' );
			// change the method to 'post'
			httpService.setMethod( 'post' ); 
			// and the content-type to json
			httpService.addParam( type = 'header', name='Content-Type', value = 'application/json' );
			// and send the json in the body of the request
			httpService.addParam( type = 'body', value = arguments.options );
		}

		// send the http request and get the result
		result = httpService.send().getPrefix();

		// check if the status code is in the 200's
		if( result.statusCode lt 300 ) {
			// it is, generate an image from the file content
			return imageNew( source = result.fileContent );
		// otherwise
		} else {
			// an error occurred, return the details of the error
			return deserializeJSON( result.fileContent );
		}
	}

}