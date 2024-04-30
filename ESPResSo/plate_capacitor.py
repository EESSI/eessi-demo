"""
Simulate charged particles confined between two plates of a capacitor with
a potential difference. The system is periodic in the *xy*-plane but has a gap
in the *z*-direction. The ELC method subtracts the electrostatic contribution
from the periodic images in the *z*-direction. The system total charge is zero.
For more details, see :ref:`Electrostatic Layer Correction (ELC)`.
"""

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Agg')
#matplotlib.use('Qt5Agg')  # only to show plot in window, requires X11 forwarding
plt.rcParams.update({"font.size": 16})
np.random.seed(seed=41)

import espressomd
import espressomd.shapes
import espressomd.electrostatics
import espressomd.observables
#import espressomd.visualization

required_features = ["P3M", "WCA"]
espressomd.assert_features(required_features)

box_l = 20
elc_gap = 10
potential_diff = -3.
system = espressomd.System(box_l=[box_l, box_l, box_l + elc_gap])
#visualizer = espressomd.visualization.openGLLive(
#    system,
#    background_color=[1, 1, 1],
#    constraint_type_colors=[[0, 0, 0]],
#    camera_position=[70, 10, 15],
#    camera_right=[0, 0, -1])

system.time_step = 0.02
system.cell_system.skin = 0.4

qion = 1.
for i in range(400):
    rpos = np.random.random(3) * box_l
    system.part.add(pos=rpos, type=0, q=(-1)**i * qion)

system.constraints.add(shape=espressomd.shapes.Wall(
    dist=0, normal=[0, 0, 1]), particle_type=1)
system.constraints.add(shape=espressomd.shapes.Wall(
    dist=-box_l, normal=[0, 0, -1]), particle_type=1)

system.non_bonded_inter[0, 1].wca.set_params(epsilon=1.0, sigma=1.0)
system.non_bonded_inter[0, 0].wca.set_params(epsilon=1.0, sigma=1.0)

system.integrator.set_steepest_descent(f_max=10, gamma=50.0,
                                       max_displacement=0.2)
system.integrator.run(1000)
system.integrator.set_vv()
system.thermostat.set_langevin(kT=0.1, gamma=1.0, seed=42)

p3m = espressomd.electrostatics.P3M(prefactor=1.0, accuracy=1e-2, verbose=False)
elc = espressomd.electrostatics.ELC(
    actor=p3m, maxPWerror=1.0, gap_size=elc_gap, const_pot=True,
    pot_diff=potential_diff, delta_mid_top=-1., delta_mid_bot=-1.)
system.actors.add(elc)


def moving_average(x, w):
    return np.convolve(x, np.ones(w), "valid") / w

def make_plot(series_anion, series_cation, name):
    plt.plot(moving_average(series_anion, 3), label=f"anions, t={system.time:.0f}")
    plt.plot(moving_average(series_cation, 3), label=f"cations, t={system.time:.0f}")
    plt.ylim((0., 0.08))
    plt.xlabel("Position along the z-axis (A.U.)")
    plt.ylabel("Probability density function")
    plt.title("Charge separation in an electrolytic\nplate capacitor model")
    plt.legend(loc="upper center")
    plt.tight_layout()
    plt.savefig("%s.png" % name, dpi=192)
    # plt.show()  # requires to have X11 forwarding enabled

kwargs = {
    "n_x_bins": 1,
    "n_y_bins": 1,
    "n_z_bins": 40,
    "min_x": 0.0,
    "max_x": box_l,
    "min_y": 0.0,
    "max_y": box_l,
    "min_z": 0.0,
    "max_z": box_l,
}
obs_anion = espressomd.observables.DensityProfile(ids=list(system.part.select(lambda p: p.q < 0).id), **kwargs)
obs_cation = espressomd.observables.DensityProfile(ids=list(system.part.select(lambda p: p.q > 0).id), **kwargs)

make_plot(obs_anion.calculate()[0, 0, 1:-1], obs_cation.calculate()[0, 0, 1:-1], name="plate_capacitor_before")

system.integrator.run(2000)
make_plot(obs_anion.calculate()[0, 0, 1:-1], obs_cation.calculate()[0, 0, 1:-1], name="plate_capacitor_after")

#visualizer.run(1)
