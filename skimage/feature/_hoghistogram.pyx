# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False

import numpy as np
cimport numpy as cnp

# cnp.float64_t[:, :] magnitude
cdef float CellHog(cnp.ndarray[cnp.float64_t, ndim=2] magnitude,
    cnp.ndarray[cnp.float64_t, ndim=2] orientation,
    float ori1, float ori2,
    int cx, int cy, int xi, int yi, int sx, int sy):
    """CellHog

    Parameters
    ----------
    magnitude : ndarray
        The gradient magnitudes of the pixels.
    orientation : ndarray
        Lookup table for orientations.
    ori1 : float
        Orientation range start.
    ori2 : float
        Orientation range end.
    cx : int
        Pixels per cell (x).
    cy : int
        Pixels per cell (y).
    xi : int
        Block index (x).
    yi : int
        Block index (y).
    sx : int
        Image size (x).
    sy : int
        Image size (y).

    Returns
    -------
    total : float
        The total HOG value.
    """
    cdef int cx1, cy1

    cdef float total = 0.
    for cy1 in range(-cy/2, cy/2):
        for cx1 in range(-cx/2, cx/2):
            if (yi + cy1 < 0 
                or yi + cy1 >= sy 
                or xi + cx1 < 0
                or xi + cx1 >= sx 
                or orientation[yi + cy1, xi + cx1] >= ori1
                or orientation[yi + cy1, xi + cx1] < ori2): continue

            total += magnitude[yi + cy1, xi + cx1]

    return total

def HogHistograms(cnp.ndarray[cnp.float64_t, ndim=2] gx,
    cnp.ndarray[cnp.float64_t, ndim=2] gy,
    int cx, int cy, 
    int sx, int sy, 
    int n_cellsx, int n_cellsy, 
    int visualise, int orientations, 
    cnp.ndarray[cnp.float64_t, ndim=3] orientation_histogram):
    """Extract Histogram of Oriented Gradients (HOG) for a given image.

    Parameters
    ----------
    gx : ndarray
        First order image gradients (x).
    gy : ndarray
        First order image gradients (y).
    cx : int
        Pixels per cell (x).
    cy : int
        Pixels per cell (y).
    sx : int
        Image size (x).
    sy : int
        Image size (y).
    n_cellsx : int
        Number of cells (x).
    n_cellsy : int
        Number of cells (y).
    visualise : int
        Also return an image of the HOG.
    orientations : int
        Number of orientation bins.
    orientation_histogram : ndarray
        The histogram to fill.
    """

    cdef cnp.ndarray[cnp.float64_t, ndim=2] magnitude = np.hypot(gx, gy)
    cdef cnp.ndarray[cnp.float64_t, ndim=2] orientation = (
        np.arctan2(gy, gx) * (180 / np.pi) % 180)
    cdef int i, x, y, o, yi, xi, cy1, cy2, cx1, cx2
    cdef float ori1, ori2

    # compute orientations integral images

    for i in range(orientations):
        # isolate orientations in this range

        ori1 = 180. / orientations * (i + 1)
        ori2 = 180. / orientations * i

        y = cy / 2
        cy2 = cy * n_cellsy
        x = cx / 2
        cx2 = cx * n_cellsx
        yi = 0
        xi = 0

        while y < cy2:
            xi = 0
            x = cx / 2

            while x < cx2:
                orientation_histogram[yi, xi, i] = CellHog(magnitude, 
                    orientation, ori1, ori2, cx, cy, x, y, sx, sy)
                xi += 1
                x += cx

            yi += 1
            y += cy

