#include <math.h>
#include "mex.h"
#include "UGM_common.h"
#include "edgePot.h"

// compileme with
// mex -Imex -outdir mrf mrf/UGM_Infer_LBPC_PR.c

/*************************************************************************************************
 * This file is a modification of UGM_Infer_LBPC to work with computing edgePot on the fly. 
 * This is a bit slower than pre-computing the edge potential (TODO: how much slower?), 
 * but can be used on huge data, which is otherwise a problem. Additionally, edgeBel and logZ 
 * are *not* computed anymore, to avoid other large variables.
 *
 * Instead of 
 *  UGM_Infer_LBPC(nodePot, edgePot, edgeEnds, nStates, V, E, maxIter)
 * we now have
 *  UGM_Infer_LBPC(nodePot, statedispl, lambda_edge, edgeEnds, nStates, V, E, maxIter)
 * where
 *  statedispl is a nNodes-by-dim-by-nStates
 *  lambda_edge is a double
 *
 * TODO: what we would *like* to have, which will require a lot less memory, is the following. 
 * This unfortunately would requite a re-write of singlescale
 *  UGM_Infer_LBPC(nodePot, displ, stateOffsets, lambda_edge, edgeEnds, nStates, V, E, maxIter)
 * where
 *  displ is nNodes-by-stateDim (e.g. Nx3) stating the current displacement of the nodes
 *  stateOffsets is nStates-by-stateDim (e.g. 27x3) stating the offset of each state 
 *      (usually, the middle state will have [0, 0, 0] offset, for example)
 *  lambda_edge is a double
 *************************************************************************************************/


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Variables */
  int n, s,e,e2,n1,n2,neigh,Vind,Vind2,s1,s2, dim,
    nNodes, nEdges, maxState, dims[3],
    iter,maxIter,nNbrs,
    *edgeEnds, *nStates, *V, *E,*y;
  
  double *nodePot, *displ, *nodeBel, *edgeBel, *logZ, lambda_edge,
    z,energy1,energy2,entropy1,entropy2,*prodMsgs,*oldMsgs,*newMsgs,*tmp;
  
  /* Input */
  nodePot = mxGetPr(prhs[0]);
  displ = mxGetPr(prhs[1]); // N * D
  lambda_edge = ((double*)mxGetPr(prhs[2]))[0];
  edgeEnds = (int*)mxGetPr(prhs[3]);
  nStates = (int*)mxGetPr(prhs[4]);
  V = (int*)mxGetPr(prhs[5]);
  E = (int*)mxGetPr(prhs[6]);
  maxIter = ((int*)mxGetPr(prhs[7]))[0];
  
  if (!mxIsClass(prhs[3],"int32")||!mxIsClass(prhs[4],"int32")||!mxIsClass(prhs[5],"int32")||!mxIsClass(prhs[6],"int32")||!mxIsClass(prhs[7],"int32"))
      mexErrMsgTxt("edgeEnds, nStates, V, E, maxIter must be int32");

  /* Compute Sizes */
  dim = mxGetDimensions(prhs[1])[1];
  nNodes = mxGetDimensions(prhs[0])[0];
  maxState = mxGetDimensions(prhs[0])[1];
  nEdges = mxGetDimensions(prhs[3])[0];
  
   /* Output */
  plhs[0] = mxCreateDoubleMatrix(nNodes,maxState,mxREAL);
  dims[0] = 1; //maxState;
  dims[1] = 1; //maxState;
  dims[2] = 1; //nEdges;
  plhs[1] = mxCreateNumericArray(3,dims,mxDOUBLE_CLASS,mxREAL);
  plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
  nodeBel = mxGetPr(plhs[0]);
  edgeBel = mxGetPr(plhs[1]);
  logZ = mxGetPr(plhs[2]);
  
  prodMsgs = mxCalloc(maxState*nNodes,sizeof(double));
  oldMsgs = mxCalloc(maxState*nEdges*2,sizeof(double));
  newMsgs = mxCalloc(maxState*nEdges*2,sizeof(double));
  tmp = mxCalloc(maxState,sizeof(double));
  
  /* Initialize */
  for(e = 0; e < nEdges; e++)
  {
    n1 = edgeEnds[e]-1;
    n2 = edgeEnds[e+nEdges]-1;
    for(s = 0; s < nStates[n2]; s++)
      newMsgs[s+maxState*e] = 1./nStates[n2];
    for(s = 0; s < nStates[n1]; s++)
      newMsgs[s+maxState*(e+nEdges)] = 1./nStates[n1];
  }
  
  for(iter = 0; iter < maxIter; iter++)
  {
    
    for(n=0;n<nNodes;n++)
    {
      
      /* Update Messages */
      for(Vind = V[n]-1; Vind < V[n+1]-1; Vind++)
      {
        e = E[Vind]-1;
        n1 = edgeEnds[e]-1;
        n2 = edgeEnds[e+nEdges]-1;
        
        /* First part of message is nodePot*/
        for(s = 0; s < nStates[n]; s++)
          tmp[s] = nodePot[n + nNodes*s];
        
        /* Multiply by messages from neighbors except j */
        for(Vind2 = V[n]-1; Vind2 < V[n+1]-1; Vind2++)
        {
          e2 = E[Vind2]-1;
          if (e != e2)
          {
            if (n == edgeEnds[e2+nEdges]-1)
            {
              for(s = 0; s < nStates[n]; s++)
              {
                tmp[s] *= newMsgs[s+maxState*e2];
              }
            }
            else
            {
              for(s = 0; s < nStates[n]; s++)
              {
                tmp[s] *= newMsgs[s+maxState*(e2+nEdges)];
              }
            }
          }
        }
        
        /* Now multiply by edge potential to get new message */
        
        if (n == n2)
        {
          for(s1 = 0; s1 < nStates[n1]; s1++)
          {
            newMsgs[s1+maxState*(e+nEdges)] = 0.0;
            for(s2 = 0; s2 < nStates[n2]; s2++)
            {
              // newMsgs[s1+maxState*(e+nEdges)] += tmp[s2]*edgePot[s1+maxState*(s2+maxState*e)];
              
              // This is where, instead of simply looking up the edge potential, we have to compute
              // the right value
              newMsgs[s1+maxState*(e+nEdges)] += tmp[s2] * 
                      edgePot(displ, n1, s1, n2, s2, dim, nNodes, nStates, lambda_edge);
            }
          }
          
          /* Normalize */
          z = 0.0;
          for(s = 0; s < nStates[n1]; s++)
            z += newMsgs[s+maxState*(e+nEdges)];
          for(s = 0; s < nStates[n1]; s++)
            newMsgs[s+maxState*(e+nEdges)] /= z;
        }
        else
        {
          for(s2 = 0; s2 < nStates[n2]; s2++)
          {
            newMsgs[s2+maxState*e] = 0.0;
            for(s1 = 0; s1 < nStates[n1]; s1++)
            {
              // newMsgs[s2+maxState*e] += tmp[s1]*edgePot[s1+maxState*(s2+maxState*e)];
              newMsgs[s2+maxState*e] += tmp[s1] *
                      edgePot(displ, n1, s1, n2, s2, dim, nNodes, nStates, lambda_edge);
            }
            
          }
          
          /* Normalize */
          z = 0.0;
          for(s = 0; s < nStates[n2]; s++)
            z += newMsgs[s+maxState*e];
          for(s = 0; s < nStates[n2]; s++)
            newMsgs[s+maxState*e] /= z;
        } 
      }
    }
    
    /* oldMsgs = newMsgs */
    z = 0;
    for(s=0;s<maxState;s++)
    {
      for(e=0;e<nEdges*2;e++)
      {
        z += absDif(newMsgs[s+maxState*e],oldMsgs[s+maxState*e]);
        oldMsgs[s+maxState*e] = newMsgs[s+maxState*e];
      }
    }
    
    /* if sum(abs(newMsgs(:)-oldMsgs(:))) < 1e-4; break; */
    if(z < 1e-4) { break; }
  }
  
  /*if(iter == maxIter)
  {
    printf("LBP reached maxIter of %d iterations\n",maxIter);
  }
   printf("Stopped after %d iterations\n",iter); */
  
  /* compute nodeBel */
  for(n = 0; n < nNodes; n++)
  {
    for(s = 0; s < nStates[n]; s++)
      prodMsgs[s+maxState*n] = nodePot[n+nNodes*s];
    
    for(Vind = V[n]-1; Vind < V[n+1]-1; Vind++)
    {
      e = E[Vind]-1;
      n1 = edgeEnds[e]-1;
      n2 = edgeEnds[e+nEdges]-1;
      
      if (n == n2)
      {
        for(s = 0; s < nStates[n]; s++)
        {
          prodMsgs[s+maxState*n] *= newMsgs[s+maxState*e];
        }
      }
      else
      {
        for(s = 0; s < nStates[n]; s++)
        {
          prodMsgs[s+maxState*n] *= newMsgs[s+maxState*(e+nEdges)];
        }
      }
    }
    
    z = 0;
    for(s = 0; s < nStates[n]; s++)
    {
      nodeBel[n + nNodes*s] = prodMsgs[s+maxState*n];
      z = z + nodeBel[n+nNodes*s];
    }
    for(s = 0; s < nStates[n]; s++)
      nodeBel[n + nNodes*s] /= z;
  }
  
  logZ[0] = 0;
  
  /* Free memory */
  mxFree(prodMsgs);
  mxFree(oldMsgs);
  mxFree(newMsgs);
  mxFree(tmp);
}
