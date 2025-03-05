#
# Copyright (C) 2010-2022 The ESPResSo project
#
# This file is part of ESPResSo.
#
# ESPResSo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ESPResSo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

"""
Visualize the Poiseuille flow in a lattice-Boltzmann fluid with an
external force applied. The CPU implementation runs best on 8 cores.
The GPU implementation only needs 1 core.
"""

import matplotlib.pyplot as plt
import matplotlib as mpl
import mpl_ascii
import argparse
import numpy as np
import tqdm
import espressomd
import espressomd.lb
import espressomd.lbboundaries
import espressomd.shapes

mpl_ascii.AXES_WIDTH=100
mpl_ascii.AXES_HEIGHT=24
mpl.use("module://mpl_ascii")

parser = argparse.ArgumentParser(description="Poiseuille flow in a rectangular channel.")
parser.add_argument("--gpu", default=False, action="store_true")
args = parser.parse_args()

required_features = ["LB_BOUNDARIES", "EXTERNAL_FORCES"]
if args.gpu:
    required_features += ["CUDA", "LB_BOUNDARIES_GPU"]
espressomd.assert_features(required_features)

BOX_L_X = 16.
BOX_L_Y = 12.
BOX_L_Z = 12.
TIME_STEP = 0.001
AGRID = 0.5
VISCOSITY = 2.0
FORCE_DENSITY = [0.0, 0.001, 0.0]
DENSITY = 1.5
WALL_OFFSET = AGRID
HEIGHT = BOX_L_X - 2.0 * AGRID

def poiseuille_flow(x, force_density, dynamic_viscosity, height):
    return force_density / (2 * dynamic_viscosity) * (height**2 / 4 - x**2)

system = espressomd.System(box_l=[BOX_L_X, BOX_L_Y, BOX_L_Z])
system.time_step = TIME_STEP
system.cell_system.skin = 0.4

if args.gpu:
    LBFluid = espressomd.lb.LBFluidGPU
else:
    LBFluid = espressomd.lb.LBFluid
lbf = LBFluid(agrid=AGRID, dens=DENSITY, visc=VISCOSITY,
              tau=TIME_STEP, ext_force_density=FORCE_DENSITY)
system.actors.add(lbf)
top_wall = espressomd.shapes.Wall(normal=[1, 0, 0], dist=WALL_OFFSET)
bottom_wall = espressomd.shapes.Wall(normal=[-1, 0, 0], dist=-(BOX_L_X - WALL_OFFSET))
top_boundary = espressomd.lbboundaries.LBBoundary(shape=top_wall)
bottom_boundary = espressomd.lbboundaries.LBBoundary(shape=bottom_wall)
system.lbboundaries.add(top_boundary)
system.lbboundaries.add(bottom_boundary)

sim_xdata = (np.arange(lbf.shape[0]) + 0.5) * AGRID
sim_ydata_list = []
for i in tqdm.trange(30, mininterval=0.001):
    system.integrator.run(1100)
    if (i + 1) % 10 == 0:
        fluid_velocities = (lbf[:,:,:].velocity)[:,:,:,1]
        fluid_velocities = np.average(fluid_velocities, axis=(1,2))
        sim_ydata_list.append((system.time, fluid_velocities))

ref_xdata = np.linspace(0.0, BOX_L_X, lbf.shape[0])
ref_ydata = poiseuille_flow(ref_xdata - (HEIGHT / 2 + AGRID), FORCE_DENSITY[1],
                           VISCOSITY * DENSITY, HEIGHT)
# velocity is zero inside the walls
ref_ydata[np.nonzero(ref_xdata < WALL_OFFSET)] = 0.0
ref_ydata[np.nonzero(ref_xdata > BOX_L_X - WALL_OFFSET)] = 0.0

print("\n\n")

fig, ax = plt.subplots()
ax.scatter(ref_xdata, ref_ydata, label="Analytical solution")
for sim_time, sim_ydata in sim_ydata_list[::-1]:
    ax.scatter(sim_xdata, sim_ydata,  label=f"Simulation at t={sim_time:.0f}")

ax.set_title("Poiseuille flow in a rectangular channel")
ax.set_xlabel("Position on the x-axis")
ax.set_ylabel("v")
ax.legend(title=None)
plt.show()
