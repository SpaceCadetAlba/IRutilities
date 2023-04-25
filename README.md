# IRutilities
Some handy Matlab IR processing functions

Contents:
- directTruncate:
  Used to truncate IR from the beginning of an audio file to the start of the direct sound on a specified channel with a specified pre-ring time and a linear fade in.
- removeDirect:
  Used to truncate IR to an estimation of the 1st (ground) reflection based upon source and receiver distances, using the specified channel
- decayAdjust
  Used to generate and apply an attenuation envelope for altering the decay envelope of impulse response using measured and desired RT60.
