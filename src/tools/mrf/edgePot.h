/* edge potential function (instead of the variable) */

/* Version 1 - even less memory, but not quite easily possible in current implementation of PR 
 *   see notes in UGM_Infer_LBPC_PR
 * double edgePot(double* displ, double* offset, double n1, double s1, double n2, double s2, 
 *         double dim, double nNodes, double nStates, double lambda_edge) {    
 *     double v1, v2, d, s;
 *     int i;
 *     
 *     // sum of squared differences
 *     s = 0;
 *     for (i = 0; i < dim; i++) {
 *         v1 = displ[nNodes * i + n1] + offset[nStates * i + s1];
 *         v2 = displ[nNodes * i + n2] + offset[nStates * i + s2];
 *         d = v1[i] - v2[i];
 *         s = s + d*d;
 *     }
 *     
 *     // exponential distance
 *     s = sqrt(s);
 *     return exp(-lambda_edge * s);
 * }
 */

/* Version 2 */
double edgePot(double* displ, int n1, int s1, int n2, int s2, 
        int dim, int nNodes, int nStates, double lambda_edge) {    
    double v1, v2, d, s;
    int i;
    
    /* sum of squared differences */
    s = 0;
    for (i = 0; i < dim; i++) {
        v1 = displ[nNodes * i + n1 + (nNodes * dim) * s1];
        v2 = displ[nNodes * i + n2 + (nNodes * dim) * s2];
        d = v1 - v2;
        s = s + d*d;
    }
    
    /* exponential distance */
    s = sqrt(s);
    return exp(-lambda_edge * s);
}
