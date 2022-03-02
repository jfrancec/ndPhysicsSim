### N-Dimensional Particle Simulation

Hi! Welcome to the insanity of this project. We have pie, ice cream,
and a bowl of tears to cry into whenever you look at this code. I'm
not saying they have to be tears of sadness or tears of joy. That
entirely depends on how well the code has been created and commented,
if it stays that way, and if you don't vehemently hate the way the
system parameters are set up. 

Important things to know: There are currently two projects in this
repository, one called `physSimNDEM` and another with an `RF` after
it. The original version deals with inelastic particle collisions,
which comes with the issue of when the permitivity of free space is
too large, dipoles will begin to spontaneously spin, violating the
conservation of energy. However, if you're willing to turn up the 
framerate or turn down eps, everything should run more-or-less
alright with only second order issues.

The file containing `RF` in it's name represents completely elastic
collisions of particles. Now, when two paticles collide, their
velocity in the direction of the distance vector is not set to 0.
Instead, there is just a repulsive force when the particles get too
close. Changing the strength of this force amounts to changing the
variable `delta` in the code around line 150.

Hopefully the rest of the parameters at the top of the code are
self-explanatory from the comments there and from their names. Happy
coding!
