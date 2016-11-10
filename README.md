## Simple DICOM RT Viewer for MATLAB&reg;

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2016, University of Wisconsin Board of Regents

The Simple DICOM RT Viewer is a MATLAB graphical user interface that loads and displays the contents of DICOM CT, RT Structure Set, and RT Dose files. The interface allows the user to select a folder to scan for DICOM files, then loads the file contents into a series of simple MATLAB objects and displays the CT transverse, coronal, and sagittal axes with overlaying contours and dose colorwash. An RT structure Set and RT Dose file is optional, but if provided, a DVH will also be displayed along with a table for adjusting contour display and reporting the dose values for a given relative volume.

This tool uses the [DICOM Manipulation Tools](https://github.com/mwgeurts/dicom_tools) functions for reading the DICOM files.
