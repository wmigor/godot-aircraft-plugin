import aerosandbox as asb
import aerosandbox.numpy as np
import matplotlib.pyplot as plt

def plot_airfoil(airfoil_name, deflection=0.0, hinge_point_x=0.75):
    airfoil = asb.Airfoil(airfoil_name).add_control_surface(deflection, hinge_point_x)
    alphas = np.linspace(-180, 180, 360)
    results = airfoil.get_aero_from_neuralfoil(alpha=alphas, Re=1e6, mach=0.0)

    figure, axis = plt.subplots()
    plt.grid()
    axis.plot(alphas, results["CL"], color="green", label="CL")
    axis.plot(alphas, results["CD"], color="red", label="CD")
    axis.plot(alphas, results["CM"], color="yellow", label="CM")
    plt.xlabel("angle")
    plt.ylabel("coefficients")
    plt.title("Airfoil \"{}\", deflection: {}, hinge: {}".format(airfoil_name, deflection, hinge_point_x))
    plt.show()


def save_airfoil(file_name, airfoil_name, deflections=None, hinge_point_x=0.75):
    angles = []
    a = -180.0
    step = 1.0
    while a <= 180.0:
        angles.append(a)
        a += step
    alphas = np.array(angles)
    deflections = deflections or [0.0]
    lifts = {}
    drags = {}
    pitches = {}
    for deflection in deflections:
        airfoil = asb.Airfoil(airfoil_name).add_control_surface(deflection, hinge_point_x)
        results = airfoil.get_aero_from_neuralfoil(alpha=alphas, Re=1e6, mach=0.0)
        lifts[deflection] = list(results["CL"])
        drags[deflection] = list(results["CD"])
        pitches[deflection] = list(results["CM"])
    with open(file_name, "w") as file:
        file.write("CL CD CM\n")
        file.write("{}\n".format(" ".join(str(d) for d in deflections)))
        for i in range(len(alphas)):
            file.write("{} ".format(alphas[i]))
            for deflection in deflections:
                file.write("{} {} {} ".format(lifts[deflection][i], drags[deflection][i], pitches[deflection][i]))
            file.write("\n")

# plot_airfoil("naca2412", 0.0, 0.75)
# plot_airfoil("naca2412", 10.0, 0.75)
# plot_airfoil("naca2412", 20.0, 0.75)
# plot_airfoil("naca2412", 30.0, 0.75)
# plot_airfoil("naca2412", 40.0, 0.75)
# plot_airfoil("naca2412", 45.0, 0.75)


deflections = [-50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50]
save_airfoil("naca2412", "naca2412", deflections)
save_airfoil("naca0012", "naca0012", deflections)