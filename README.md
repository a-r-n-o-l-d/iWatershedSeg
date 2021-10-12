# iWatershedSeg

## Install
1. install `MorphoLibJ` in Fiji/Imagej
2. copy `iWatershedSeg.ijm` and `icons` folder in `Fiji.app/macros/toolset` directory
3. copy the content of `luts` into `Fiji.app/luts` directory

## Usage

### Toolbar description
![toolbar](assets/toolbar.png)

1. start/load a segmentation project
2. brush tool to mark the inside of an object to be segmented
3. brush tool to mark the outside of an object to be segmented
4. eraser: reset a mark to background
5. launch the marker controlled watershed algorithm
6. record the result of watershed
7. move to one frame backward if your input data is a time serie
8. move to one frame forward if your input data is a time serie
9. extra tools like saving a project

### Start a project
![toolbar](assets/Screenshot_1.png)