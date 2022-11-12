`dashboard2.jl` contains the code to make plots for SHL data in all background \
runs of CR2154. It is called in `main.jl` from where the app is launched.

To run the app locally:

Clone this folder and do the following:

1. Download Julia (1.7.2 for Mac):

https://julialang-s3.julialang.org/bin/mac/x64/1.7/julia-1.7.2-mac64.tar.gz

2. Create a symbolic link for the extracted folder from the above file. for eg
```
ln -s /absolute path to extracted folder/bin/julia /usr/local/bin/julia
```

3. `cd` into correct folder

4. Launch julia from command line, if `/usr/local/bin` is in $PATH, then typing\
 `julia` should be enough. The following welcome screen should appear:

```julia
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.7.2 (2022-02-06)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia>

```
Type `pwd()` to ensure we are in the right folder . If not we can do `cd("/path/to/cloned/dir")` from within julia.

5. Hit `]` to go into Pkg mode (backspace returns to regular `julia>` mode)

6. `activate .` for activating Project environment

7. `instantiate` to install and resolve all dependencies.

8. Run `main.jl` using `include("main.jl")` from the Julia REPL. This will be slow the first time.

9. If all goes well, the output is:

```julia
[ Info: For saving to png with the Plotly backend PlotlyBase has to be installe\
d.
[ Info: Listening on: 0.0.0.0:8080
```
10. Navigate to `127.0.0.1:8080` in the browser

11. To close app, hit `Ctrl + C` in the Julia REPL.


















