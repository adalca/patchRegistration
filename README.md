# PBR: Patch-Based Discrete Registration 
Patch-based discrete registration for two n-dimensional volumes (e.g. images or medical 3D volumes).

## Quick Start
To quickly register two volumes:
- download package
- download required libraries (specified in `setup.m`)
- open and modify `setup.m`, adding necessary paths
- modify example parameter file `config/params.ini`. Each parameter has a description.
- modify example paths file `config/paths.ini` for the input and output files
- run `registerNii()` to register volumes

### Parameter Files
The `config` folder contains an example parameter file `params.ini`. All parameters are briefly described there.

### 3D Medical Registration
The `config` folder contains an example paths input file `paths.ini`. In essence, this file contains the path to the moving, fixed and output files. 
Finally, run `registerNii('/paths/to/paths.ini', '/paths/to/params.ini')` to register the volumes. 

### 2D Image Registration
A wrapper for running 2D registration is in defelopment, but it should be quite easy to run `patchreg.multiscale` with a params file similar to the one in the `config` folder.

## Contact
The quickest way to get help is to open a [github issue](https://github.com/adalca/patchRegistration/issues).  
Please also feel free to email us at {adalca,abobu}@csail.mit.edu  

## Reference  
[Adrian V. Dalca](http://adalca.mit.edu), [Andreea Bobu](https://people.eecs.berkeley.edu/~abobu/), [Natalia Rost](https://www.massgeneral.org/doctors/doctor.aspx?id=17477), [Polina Golland](https://people.csail.mit.edu/polina/)  
Patch-Based Discrete Registration of Clinical Brain Images  
*In Proc. MICCAI-PATCHMI Patch-based Techniques in Medical Imaging*, LNCS 9993, pp 60-67, 2016.  
[bibtex](reference.bib)