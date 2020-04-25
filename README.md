# smfish-detector
This is a set of MATLAB scripts to help label and count fluorescent labels in images of cells. For instance, these scripts were used to detect RNA fluorescence *in situ* hybridization experiments.

It can also automatically detect the edge around fluorescence in an image to determine cell boundaries. The method is robust to random noise outside of the true cell boundary.

## How to run the code
### Pre-requisites
- MATLAB (at least 2009b)
- Install [VLFeat](https://www.vlfeat.org/install-matlab.html)

### Steps
1. Clone this repository
2. Open MATLAB
3. In the MATLAB command window, navigate to the location where you cloned this repository
4. Run "main.m" (right click on "main.m" in the file browser in MATLAB, then click "Run" from the drop down menu)
