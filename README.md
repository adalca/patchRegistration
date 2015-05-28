# patchRegistration
Patch based Discrete Registration.



# Coding TODOs
+sim
---
 - transform `+sim.ball3D()` and `+sim.ball2D()` into `+sim.ovoidShift(vol, radius, verbose)`. This function creates a n-dimentional displacement ball, where `n = ndims(vol)`, and apply the displacement to `vol`. `radius` is a scalar in (0, inf), or a vector of size 1 x n where each entry is (0, inf). If it's a scalar, then: (1) if radius in (0, 1) indicates a fractional radius with respect to the size of the volume; (2) if radius is in [1, inf), then the radius is assumed to be given in actual units. If radius is a vector, then each displacement volume gets its own radius. `verbose` is a `logical` on whether to display the results or not (only applicable if n == 2 or n == 3).

 - `+sim.randShift(vol, verbose)` similar to ovoidShift but instead of creating the ball shift simply use random fields of n dimensions.
