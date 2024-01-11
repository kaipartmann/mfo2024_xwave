
# Julia code wave propagation simulation
```
Fracture as an Emergent Phenomenon
Oberwolfach, 2024

talk:
Peridynamic modeling of the interplay of wave propagation and dynamic fracture
```

## Installation

To install `Peridynamics.jl`, follow these steps:

1. Install Julia from the [official Julia website](https://julialang.org/) if you haven't already.
   We recommend using [`juliaup`](https://github.com/JuliaLang/juliaup).\
   **Windows:**\
   Install `juliaup` from the Windows Store (https://www.microsoft.com/store/apps/9NJNWW8PVKMN) or via the following command:
   ```
   winget install julia -s msstore
   ```
   **MacOS & Linux:**\
   Install `juliaup` with the command:
   ```
   curl -fsSL https://install.julialang.org | sh
   ```

2. Launch Julia and open the Julia REPL.

3. Enter the package manager by pressing `]` in the REPL.

4. In the package manager, type the following commands (take up to minutes at the first time):
   ```
   (mfo2024_xwave) pkg> activate .

   (mfo2024_xwave) pkg> instantiate
   ```

5. Press `Backspace` or `Ctrl + C` to exit the package manager.

## Only simulation - `xwave.jl`
If you just want to run the simulation (code seen in the talk) and look at the results via ParaView (https://www.paraview.org), then run the script `xwave.jl` in the repository.

```julia
using Peridynamics
lx, lyz, Δx = 0.2, 0.002, 0.002/6
pc = PointCloud(lx, lyz, lyz, Δx)
mat = BondBasedMaterial(horizon=3.015Δx, rho=7850, E=210e9,
                        epsilon_c=1)
T, vmax = 1e-5, 2
points_fix_left = findall(pc.position[1,:] .< -lx/2+1.2Δx)
v_x(t) = t < T ? vmax * sin(2π/T * t) : 0
bcs = [VelocityBC(v_x, points_fix_left, 1)]
es = ExportSettings("results", 10); mkpath("results")
vv = VelocityVerlet(2000)
job = PDSingleBodyAnalysis(name="xwave", pc=pc, mat=mat,
                           bcs=bcs, es=es, td=vv)
submit(job)
```

To run it with 8 threads, just type:
```
julia --project -t 8 xwave.jl
```

If you need help using ParaView for post processing, take a look at https://kaipartmann.github.io/Peridynamics.jl/stable/howto_visualization/.

## Simulation & post processing with Julia - `xwave_with_postproc.jl`
The script `xwave_with_postproc.jl` contains a function to run the simulation and also all code used to generate images of the wave and a video.

![](xwave_image.png)

To run that with 8 threads, just type:
```
julia --project -t 8 xwave_with_postproc.jl
```