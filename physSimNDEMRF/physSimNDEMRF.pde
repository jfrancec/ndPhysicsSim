import com.hamoid.*;
VideoExport videoExport;

int n = 300;
int dim = 3;
int forceCount = 1;
// Length needs to be force count
// Larger eps values indicate stronger force
//float eps[] = {100000}; // Used for 2D  R == 20
float eps[] = {40000000}; // Used for 3D   R == 20
//float eps[] = {400000000}; // Used for 4D   R == 20
//float eps[] = {600000000000f}; // Used for 5D   R == 30
//float eps[] = {4000000}; // Used for overdamped 3D   R == 20
//float eps[] = {6000000}; // Used for overdamped 3D   R == 30
// Length needs to be force count
float charges[] = {2};
// Length == forceCount, each element has dimension proportional to charges*charges
float forceTensor[][][] = {{{1, -1}, {-1, 1}}}; // For standard EM
//float forceTensor[][][] = {{{2.2, -1, -1}, {-1, 2.2, -1}, {-1, -1, 2.2}}}; // For 3 charge EM
boolean overDamped = false;


float globalR = 50;
float globalM = 1;
// Set to 1 to ignore anneling (slowly deteriorates particle velocities)
float annelingFactor = 0.999;
//float annelingFactor = 1.001; // For overdamped
float repulsiveForceStrength = 0.9; // Scales distance for repulsion to take affect
float delta = 10; // A parameter for how forceful the repulsion is
//float delta = 4; // For overdamped


// Particles will only be colored based on their first charge
// Length needs to be charges[0] or larger, each element is a color
float colors[][] = {{255,0,0}, {0,0,255}, {0,255,0}};

float kata = 0.0; // This is for 4D 'depth'
float dkata = 0.0;

// Particle positions
float pos[][];
// Particle velocities
float vel[][];
// Particle radii
float R[];
// Particle masses
float M[];
// Particle charges [particle number][charge type]
int Ch[][];
// Particle charge strengths
float Cstrength[][];

float S; // Surface hyper surface of an n-sphere
final float pi = 3.14159265;

// Number of time updates per frame
final int framesPerFrame = 6;
final float dt = 1/(30.0*framesPerFrame);

boolean doMovie = false;
float overdampedProp = 2;

void setup() {
  // Find the hyper surface volume
  float V = 1;
  float Vt, St;
  S = 2;
  for(int i = 1; i < dim; i++) {
    St = 2*pi*V;
    Vt = (1.0/i) * S;
    S = St;
    V = Vt;
  }
  // S will now have the surface volume of a hyper sphere
  
  size(1280, 720, P3D);
  pos = new float[n][dim];
  vel = new float[n][dim];
  R = new float[n];
  M = new float[n];
  float r, minr;
  Ch = new int[n][forceCount];
  Cstrength = new float[n][forceCount];
  for(int i = 0; i < n; i++) {
    // Set the strength of charge for each particle
    for(int f = 0; f < forceCount; f++) {
      Cstrength[i][f] = 1;
    }
    // Set the radius of the particles
    R[i] = globalR;
    // Set the masses of the particles
    M[i] = globalM;
    // Set initial positions and velocities
    minr = 0;
    while(minr < R[i]*R[i]) {
      for(int j = 0; j < dim; j++) {
        if(j == 0)      pos[i][j] = width*random(1);
        else if(j == 1) pos[i][j] = height*random(1);
        else if(j == 2) pos[i][j] = -height*random(1);
        else            pos[i][j] = height*(random(1)-0.5);
        vel[i][j] = 0; 
      }
      // check for particles too close
      minr = 100000;
      for(int j = 0; j < i; j++) {
        r = 0;
        for(int d = 0; d < dim; d++) {
          r += (pos[i][d]-pos[j][d])*(pos[i][d]-pos[j][d]);
        } 
        if(r < minr) minr = r;
      }
    }
    // Set the charges to random
    for(int j = 0; j < forceCount; j++) 
      Ch[i][j] = floor(random(charges[j]));
  } // end for
  
  if(doMovie) videoExport = new VideoExport(this, "3D.mp4");
  if(doMovie) videoExport.startMovie();
} // end setup

void draw(){
  // Update high dimensional depth
  kata += dkata;
  
  // Set up the screen with the bounding box
  lights();
  background(0);
  pushMatrix();
  stroke(255);
  translate(width/2, height/2, -height/2);
  noFill();
  box(width, height, height);
  popMatrix();
  
  // Draw the spheres at their current locations
  for(int i = 0; i < n; i++) {
    pushMatrix();
    if(dim > 2)
      translate(pos[i][0], pos[i][1], pos[i][2]);
    else if(dim == 2)
      translate(pos[i][0], pos[i][1], 0);
    // Color based on the first charge
    fill(colors[Ch[i][0]][0], colors[Ch[i][0]][1], colors[Ch[i][0]][2]);
    if(dim >= 4) fill(colors[Ch[i][0]][0], colors[Ch[i][0]][1], colors[Ch[i][0]][2], 255-(510.0/height)*abs(pos[i][3]-kata));
    noStroke();
    sphere(R[i]);
    popMatrix();
  } // end for
  
  // Update each particle's position
  for(int i = 0; i < framesPerFrame; i++) {
    updatePositions();
  } // end i
  
  if(doMovie) videoExport.saveFrame();
} // end draw

void updatePositions() {
  float Rvec[] = new float[dim]; // The distance vector
  float r, p, k;
  for(int i = 0; i < n; i++){
    // Update the position of particles based on the forces
    float F[] = new float[dim]; // Forces for a given particle
    for(int f = 0; f < forceCount; f++) {
      for(int d = 0; d < dim; d++) F[d] = 0;
      // Go through every other particle
      for(int j = 0; j < n; j++){
        // Don't consider the force of a particle to itself
        if(j == i) continue;
        r = 0;
        for(int d = 0; d < dim; d++) {
          Rvec[d] = pos[i][d] - pos[j][d];
          r += Rvec[d] * Rvec[d];
        }
        k = -((dim-1)/(S*(dim+delta))) * eps[f] * forceTensor[f][Ch[i][f]][Ch[j][f]] * pow(R[i], delta+1);
        for(int d = 0; d < dim; d++) {
          F[d] += (eps[f])*Cstrength[i][f]*Cstrength[j][f]*forceTensor[f][Ch[i][f]][Ch[j][f]]/(S*pow(r, dim/2.0)) * Rvec[d];
          F[d] += repulsiveForceStrength*abs(k/(pow(r, (dim+delta)/2.0))) * Rvec[d];
        }
      } // end j
      
      if(overDamped) {
        for(int d = 0; d < dim; d++)
          vel[i][d] = overdampedProp * F[d];
      }
      else{
        for(int d = 0; d < dim; d++)
          vel[i][d] += dt * F[d] / M[i];
      }
      // Perform anneling (parasitic friction
      for(int d = 0; d < dim; d++) 
        vel[i][d] *= annelingFactor;
      
    } // end forces loop  
  } // end i
  
  // Change positions of particles and resolve collisions
  for(int i = 0; i < n; i++) {
    for(int d = 0; d < dim; d++) {
      pos[i][d] += dt * vel[i][d];
    } 
  }
  
  
  for(int i = 0; i < n; i++) {  
    // Check for boundary collisions
    for(int d = 0; d < dim; d++) {
      if(d == 0) {
        if(pos[i][d] < 0 && vel[i][d] < 0) vel[i][d] *= -1;
        if(pos[i][d] > width && vel[i][d] > 0) vel[i][d] *= -1;
      }
      else if(d == 1) {
        if(pos[i][d] < 0 && vel[i][d] < 0) vel[i][d] *= -1;
        if(pos[i][d] > height && vel[i][d] > 0) vel[i][d] *= -1;
      }
      else if(d == 2){
        if(pos[i][d] < -height && vel[i][d] < 0) vel[i][d] *= -1;
        if(pos[i][d] > 0 && vel[i][d] > 0) vel[i][d] *= -1;
      }
      else {
        if(pos[i][d] < -height/2 && vel[i][d] < 0) vel[i][d] *= -1;
        if(pos[i][d] > height/2 && vel[i][d] > 0) vel[i][d] *= -1;
      }
    } // end for
    
    if(true) continue;

    // Check for particle-particle collisions
    for(int j = 0; j < n; j++) {
      // Skip when considering the same particle twice
      if(j == i) continue;
      r = 0;
      for(int d = 0; d < dim; d++) {
        Rvec[d] = pos[i][d] - pos[j][d];
        r += Rvec[d]*Rvec[d];
      }
      r = pow(r, 0.5);
      if(r < (R[i]+R[j])) {
        for(int d = 0; d < dim; d++) {
          pos[i][d] = pos[j][d] + ((R[i]+R[j])/r) * Rvec[d] - ((R[i] + R[j] - r) * Rvec[d] / (2*r));
          pos[j][d] -= ((R[i] + R[j] - r) * Rvec[d] / (2*r));
        }
        p = 0; // The projection coefficient
        for(int d = 0; d < dim; d++) {
          Rvec[d] = pos[i][d] - pos[j][d];
          p += vel[i][d]*Rvec[d];
        }
        p /= (r*r);
        for(int d = 0; d < dim; d++) {
          vel[i][d] -= p * Rvec[d];
        }
      }
    } // end j
  } // end i
  
}

void keyPressed() {
  if (key == 'q') {
    if(doMovie) videoExport.endMovie();
    exit();
  }
  
  if (key == 'w') {
    dkata = 10;
  }
  
  if (key == 's') {
    dkata = -10;
  }
}

void keyReleased() {
  if(key == 'w' || key == 's') {
    dkata = 0.0;
  }
}
