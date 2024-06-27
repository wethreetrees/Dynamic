# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.1.1] Add comment based help support

- Added support for comment based help to be used in the dynamic function definition

## [1.1.0] House cleaning

- Added use cases to test coverage
    - Simple function
    - Only static parameters
    - Pipeline dynamic parameter
    - Pipeline dynamic parameter, with end block code
    - Dynamic parameter with begin block code
    - More
- Added support for `-Force` parameter to interpret simple functions as advnaced
- Fix initial declaration of pipeline bound dynamic parameters
- Move functionality from `Resolve-DynamicFunctionDefinition` into separate private functions

## [1.0.0] Initial Release

- Initial release
