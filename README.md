miniWeb
=======

Collection of utilities implemented on top of [µWeb][muweb], the minimalistic
web framework.

  [muweb]: https://github.com/alco/muweb


## Installation

miniWeb is intended to be used as a command-line tool. You may build it from
source or download a precompiled version with mix:

```
$ mix local.install https://github.com/alco/miniweb/releases/download/v1.0/miniweb-1.0.0.ez
```


## Usage

There are 3 primary utilities comprising miniWeb:

  1. **Inspect**. Allows you to dump requests from HTTP clients to console. It is
     useful for debugging clients as not all of them have builtin facilities to
     examine the data they are sending/receiving.

  2. **Proxy**. Works as an HTTP filter/proxy, transmitting data between the
     client and a remote host, logging it in the processes or even modifying
     parts of it according to the chosen filter.

  3. **Serve**. Serves the contents of chosen directory over HTTP.


## License

This software is licensed under [the MIT license](LICENSE).
