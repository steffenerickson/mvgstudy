// build_mlib.do -- compile mvgstudy.mata into lmvgstudy.mlib (developer only).
// Run from this folder in Stata 19:  do build_mlib.do
// Rebuild whenever mvgstudy.mata changes; bump the version banner in the .mata
// at the same time.  The resulting .mlib is what mvgstudy.pkg ships.
version 19
clear all
mata: mata clear
do mvgstudy.mata                       // compiles class + free functions into memory
mata: mata mlib create lmvgstudy, dir(.) replace
mata: mata mlib add lmvgstudy *()      // everything in memory = exactly the file's contents
mata: mata mlib index
mata: mata describe using lmvgstudy    // expect: class mvgstudy() + 6 free functions
