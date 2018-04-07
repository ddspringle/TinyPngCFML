# TinyPngCFML

This is a CFC wrapper for the [TinyPng.com](https://tinypng.com/developers) API used to compress PNG and JPG file sizes.

## Usage

To use this wrapper, simply initialize it with your API key, as follows:

    // get the TinifyService
    tinifyService = new model.services.TinifyService( apiKey = '[YOUR_API_KEY]' );

You can then call the service to shrink (compress) PNG or JPG images using a local file, returning only the image data as a variable, as follows:

    // get the path to the file
    filePath = expandPath( 'myImage.png' );
    // get the image as a variable from the tinify service    
	imageData = tinifyService.shrink( filePath = filePath );

You can also call the service to shrink remote files, as follows:

    // get the image as a variable from the tinify service    
	imageData = tinifyService.shrink( url = 'http://www.domain.com/myImage.png' );

You can optionally get the results back as a struct that contains the location (url) of the file, the number of compressions  completed, compression details and the image as a variable, as follows:

    // get the path to the file
    filePath = expandPath( 'myImage.png' );
    // get the structure as a variable from the tinify service    
	returnStruct = tinifyService.shrink( filePath = filePath, returnType = 'struct' );

This returns:

    location: the location (url) of the compressed image
    compCount: the total compressions used this calendar month
    details: output size and type
    imageData: image data as a variable (to write to disk, browser, etc.)

You can also resize an image at the same time as you compress it by passing in the method (scale, fit or cover) and the height and/or width (both required for fit or cover methods), as follows:

    // get the path to the file
    filePath = expandPath( 'myImage.png' );
    // get the image as a variable from the tinify service    
	imageData = tinifyService.shrink( filePath = filePath, method = 'scale', height = 128 );
	imageData = tinifyService.shrink( filePath = filePath, method = 'scale', width = 128 );
	imageData = tinifyService.shrink( filePath = filePath, method = 'fit', width = 128, height = 128 );
	imageData = tinifyService.shrink( filePath = filePath, method = 'cover', width = 128, height = 128 );

## Bugs and Feature Requests

If you find any bugs or have a feature you'd like to see implemented in this code, please use the issues area here on GitHub to log them.

## Contributing

This project is actively being maintained and monitored by Denard Springle. If you would like to contribute to this project please feel free to fork, modify and send a pull request!

## License

The use and distribution terms for this software are covered by the Apache Software License 2.0 (http://www.apache.org/licenses/LICENSE-2.0).
