# Simple DICOM RT Viewer for MATLAB

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2017, University of Wisconsin Board of Regents

The Simple DICOM RT Viewer is a MATLAB<sup>&reg;</sup> graphical user interface that loads and displays the contents of DICOM CT/MR, RT Structure Set, and RT Dose files. The interface allows the user to select a folder to scan for DICOM files, then loads the file contents into a series of simple MATLAB objects and displays the CT transverse, coronal, and sagittal axes with overlaying contours and dose colorwash. An RT structure Set and RT Dose file is optional, but if provided, a DVH will also be displayed along with a table for adjusting contour display and reporting the dose values for a given relative volume.

This tool uses the [DICOM Manipulation Tools](https://github.com/mwgeurts/dicom_tools) functions for reading the DICOM files. MATLAB is a registered trademark of MathWorks Incorporated.

## Installation and Use

To install the Simple DICOM RT Viewer as a MATLAB App, download and execute the `Simple DICOM RT Viewer.mlappinstall` file from this directory. If downloading the repository via git, make sure to download all submodules by running  `git clone --recursive https://github.com/mwgeurts/dicom_viewer`. 

## Usage and Documentation

To run the application, execute `DicomViewer` with no arguments. Once the graphical user interface loads, click Browse and select the directory containing the DICOM files to be displayed. The directory must contain at least one DICOM CT or MR image, and may optionally also include a (Frame of Reference) associated RT Structure Set and RT Dose file. The files may be loacated within subfolders.

## Compatibility and Requirements

This application has been validated in MATLAB version 8.5 through 9.1, Image Processing Toolbox 9.2 through 9.5, and Parallel Computing Toolbox version 6.6 through 6.9 on Macintosh OSX 10.10 (Yosemite) through 10.12 (Sierra) and Windows 7.  The Image Processing Toolbox is required for execution.  The Parallel Computing Toolbox is optional and will be used to interpolate data using GPU.

## License

Released under the GNU GPL v3.0 License.  See the [LICENSE](LICENSE) file for further details.
