`dashboard2.jl` contains the code to make plots for SHL data in all background runs of CR2154.

1. Download Julia (1.7.2 for Mac):

https://julialang-s3.julialang.org/bin/mac/x64/1.7/julia-1.7.2-mac64.tar.gz

2. Create a symbolic link for it. for eg
```
ln -s /path to folder called julia/bin/julia /usr/local/bin/julia
```

3. `cd` into correct folder

4. Launch julia from command line, type `pwd()` to ensure we are in the right folder. If not we can do `cd("/path/to/dir")` from within julia.

5. Hit `]` to go into Pkg mode (backspace returns to regular `julia>` mode)

6. `activate .` for activating Project environment

7. `instantiate` to install and resolve all dependencies.

8. Run `main.jl` using `include("main.jl"). This will be slow the first time.

9. If all goes well, the output is:

```julia
[ Info: For saving to png with the Plotly backend PlotlyBase has to be installed.
[ Info: Listening on: 0.0.0.0:8080
```
10. Navigate to `127.0.0.1:8080` in the browser

11. To close app, hit `Ctrl + C` in the Julia REPL.


<!-- Heroku Deploy Button :) -->

<!-- [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy) -->
