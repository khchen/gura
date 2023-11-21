# Gura Compliance

This repository contains several tests useful for any developer working on a Gura format parser/emitter.


## Usage

The tests are a series of `.ura` files categorized in different folders.

- The tests found in the `correct` folder should not throw any errors or exceptions in a Gura format parser or writer implementation.
- Then, there are different tests in folders with the name of the exception that a parser should throw. You can check theYou can check the complete [exceptions list in official docs][exceptions].

There may be a `README.md` file inside some folders where extra clarifications are made, some exceptions or usage instructions are detailed.

Automation of these tests is not possible because exception handling is dependent on each tool used. To make it agnostic to the programming language used by the interested developer, it was decided to provide a series of files that can be easily integrated into any project.

All available files are for testing the correct parsing of Gura but do not consider methods such as Gura text emission (needed for the `dump` method). These are under the responsibility of the developer working on the implementation.

If you are interested in practical usage examples, you can check any parser project maintained by the organization (Python, JS/TS, Rust, V). All of them includes all the test listed in this repository.


## Versioning

The different versions of Gura will be considered in this repository through different [Github releases][releases], where it will be explained, in case new tests are added, what is being considered. And in case new versions of the language are published, and some tests become invalid for them, they can be differentiated through the different versions of the published releases.


## Clarification

While the use of the resources here is recommended, it should be noted that the purpose of this repository is simply to facilitate the task of developers. You should feel free to use the tests available here as you wish, adding or omitting those you consider necessary. 


## License

This repository is distributed under the terms of the MIT license.

[exceptions]: https://gura.netlify.app/docs/2.0.0/Developers/parsing#standard-errors
[releases]: https://github.com/gura-conf/testing/releases