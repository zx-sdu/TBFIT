# TBFIT
Tight-binding FITting package (TBFIT*)

Now you can fit your tight-binding parameters via Slatet-Koster method with a very little effort.

TBFIT is a scientific Fortran program for numerical tight-binding parameter fitting mainly based on Slater-Koster scheme and tight-binding calculations for the electronic band structures of given atomic and electronic configurations with a simple input interfaces. Basically TBFIT fits Slater-Koster parameters including scaling factors to your target first-principles band structure. For the fitting algorithm, Levenberg–Marquardt algorithm is used (implemented by modifying MINPACK library).

You can taste how TBFIT works and its performance in Example section. Once you get proper tight-binding parameters, you can also calculate various Berry phase related quantities, such as Berry curvature, Zak phase, Wilson's loop (Z2 index, Wannier charge center), first Chern number, and so on. In addition, density of states, eigenstate charge density or wavefunction plot, STM simulations (integerated eigenstate density within certain energy window), band structures for edge/surface geometries, E-field effects, etc.

You do not need to specify all the bond connections, instead, just provide hopping classes (whether it is 1st-, 2nd-, or 3rd-nearest-neighbor hopping) between atomic species and corresponding hopping parameter names in your input file. Then TBFIT automatically set up tight-binding hamiltonian based on your input geometry and tight-binding parameter setup as defined in input interfaces.

In the future release, I will add some routines for the Green function approach to get the surface state (or edge spectrum as well) and the routines for the spin/mirror Chern number evaluation within the given tight-binding parameter and model hamiltonian.

For the details and examples you can find documents that describes the input tags in MANUAL folder and several input/output files in EXAMPLE folder, respectively.

NOTE: 
* In the current version, very limited routines are MPI parallelized (basically k-point parallelism is applied for STM, eigenstate plot, band structure calculations, parameter fitting, density of states, and berry curvature, etc.). Unfortunately the Wilson's loop calculation routines are not parallelized yet.
* If you publish the results of TBFIT then please site as : 
  Hyun-Jung Kim. (2018, August 21). Tight-binding fitting package (TBFIT) (Version v0.2.1). Zenodo. http://doi.org/10.5281/zenodo.1401335

\* a temporary name
