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
